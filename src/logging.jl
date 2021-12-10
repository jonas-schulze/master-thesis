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
