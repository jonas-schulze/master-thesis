using CairoMakie

const COLORS = Ref{Any}(cgrad(:viridis))

function timeline(tag, stage, start, stop; colors=COLORS[])
    fig = Figure()
    Axis(
        fig[1, 1],
        ylabel = "Stage",
        xtickformat = "{:d}s",
    )

    tags = unique(tag)
    ntags = length(tags)
    p(i) = (i-1) / (ntags-1)
    colormap = Dict(t => colors[p(i)] for (i, t) in enumerate(tags))
    barplot!(
        stage,
        start,
        fillto = stop,
        direction = :x,
        color = [colormap[t] for t in tag],
    )

    labels = [string(t) for t in tags]
    elements = [PolyElement(polycolor=colormap[t]) for t in tags]
    Legend(
        fig[1, 2],
        elements,
        labels,
        "Tag",
    )

    return fig
end

function timeline(df::DataFrame, tag=:tag, stage=:n, start=:start, stop=:stop; colors=COLORS[])
    fig = timeline(
        df[!, tag],
        df[!, stage],
        df[!, start],
        df[!, stop];
        colors=colors,
    )
    return fig
end

function timeline!(ax, df, color)
    barplot!(
        ax,
        df.n,
        df.start,
        fillto = df.stop,
        direction = :x,
        color = color,
    )
end
