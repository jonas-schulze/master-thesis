unit_space = Char(0x2009) # thin space

function _scaled_maybe_integer(ticks, scale::Real, unit::String)
    sticks = scale * ticks
    if all(isinteger, sticks)
        sticks = map(Int, sticks)
    end
    map(sticks) do t
        string(t, unit_space, unit)
    end
end

xtime = (
    xlabel = "Time",
    xtickformat = ticks -> _scaled_maybe_integer(ticks, 1/100, "s")
)

xstepsize = (
    xlabel = "Step Size",
    xtickformat = ticks -> _scaled_maybe_integer(ticks, 10, "ms")
)

export unit_space, xtime, xstepsize
