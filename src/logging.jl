using DataFrames
using Base.Iterators: countfrom

logdir(args...) = datadir("logfiles", args...)

_parse(T) = Base.Fix1(Base.parse, T)

const EVENTLOG_PARSERS = Dict(
    :n => _parse(Int),
    :k => _parse(Int),
    :type => Symbol,
    :tag => Symbol,
    :time => _parse(Float64),
)

function _tokenize(::LoggingFormats.LogFmt, line::String)
    quoted = r"([\w]+)=\"([^\"]*)\""
    unquoted = r"([\w]+)=([^\"][^ ]*)"
    tokens = Pair{String,String}[]
    for r in (unquoted, quoted), m in eachmatch(r, line)
        k, v = m.captures
        push!(tokens, k => v)
    end
    return tokens
end

function _parseline(f, line::String; parsers=EVENTLOG_PARSERS)
    tokens = _tokenize(f, line)
    data = NamedTuple()
    for (k, v) in tokens
        kk = Symbol(k)
        parse = get(parsers, kk, identity)
        vv = parse(v)
        data = merge(data, (; kk => vv))
    end
    data
end

function _parsefile(f, file::String; parsers=EVENTLOG_PARSERS)
    list = NamedTuple[]
    open(file) do io
        while !eof(io)
            line = readline(io)
            data = _parseline(f, line; parsers=parsers)
            push!(list, data)
        end
    end
    return list
end

"""
    load_eventlog(f, dir; range=countfrom(1)) -> long

Load and concatenate the log files `joinpath(dir, "\$i.log")` for `i in range`,
resulting in a log in long format (tag, type, time).
The files are parsed according to `f`.
Currently, the only supported format/value is `LogFmt()` from `LoggingFormats.jl`.
"""
function load_eventlog(f, dir::String; range=countfrom(1))
    df = DataFrame()
    for i in range
        file = joinpath(dir, "$i.log")
        isfile(file) || break
        list = _parsefile(f, file)
        df2 = DataFrame(
            tag=Symbol[],
            type=Symbol[],
            n=Int[],
            k=Int[],
            time=Float64[],
        )
        for data in list
            push!(df2, data; cols=:subset)
        end
        append!(df, df2; cols=:union)
    end
    if hasproperty(df, :time)
        df[!, :time] .-= df[1, :time]
    end
    return df
end

const DEFAULT_TAGS = Ref([:WarmingUpC, :WarmingUpF, :ComputingC, :ComputingF])

"""
    prep_eventlog(long, tags=DEFAULT_TAGS[]) -> wide

Convert an event log in long format (tag, type, time) into wide format (tag, start, stop, duration).
Drop singleton events (type is not `:start` or `:stop`) and filter for tags in `tags`.
By default:

```julia
tags = [:WarmingUpC, :WarmingUpF, :ComputingC, :ComputingF]
```
"""
function prep_eventlog(long, tags=DEFAULT_TAGS[])
    wide = unstack(long, :type, :time; allowduplicates=true)
    dropmissing!(wide, [:start, :stop])
    filter!(:tag => in(tags), wide)
    wide[!, :duration] = wide.stop - wide.start
    wide
end

module TimelineModel

using DataFrames

export t_warmup, t_rampup, t_F, t_G, t_par
export t̂_par, t̂_seq

N(wide) = maximum(wide.n)
K(wide) = maximum(skipmissing(wide.k))

function t_warmup(wide)
    tags = (:WarmingUpC, :WarmingUpF)
    events = filter(:tag => in(tags), wide)
    ts = combine(
        groupby(events, :n),
        :start => (ts -> minimum(ts, init=0.0)) => :start,
        :stop  => (ts -> maximum(ts, init=0.0)) => :stop,
    )
    maximum(ts.stop - ts.start, init=0.0)
end

function t_rampup(wide)
    start = _filter(wide, tag=:ComputingC, k=0).start
    delay = diff(start)
    mean(delay) - t_G(wide)
end

t_F(wide) = median(wide[wide.tag .== :ComputingF, :duration])
t_G(wide) = median(wide[wide.tag .== :ComputingC, :duration])
t_par(long) = maximum(long.time)

function t̂_par(wide)
    tF = t_F(wide)
    tG = t_G(wide)
    t = t_warmup(wide) +
        N(wide) * (t_rampup(wide) + tG) +
        K(wide) * (tF + tG) +
        tF
    return t
end

function k_n(wide)
    # collect last fine solutions, which are computed after the last refinements
    Fs = filter(:tag => ==(:ComputingF), wide)
    combine(
        groupby(Fs, :n),
        :k => maximum => :k,
    )
end

function t̂_seq(wide)
    Fs = filter(:tag => ==(:ComputingF), wide)
    kₙ = k_n(wide)
    F_kₙ = innerjoin(Fs, kₙ, on=names(kₙ))
    sum(F_kₙ.duration)
end

end
