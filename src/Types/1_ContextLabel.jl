## ------------------------------------------------------------------
# An object optimized to be hashable and pushable
struct ContextLabel
    vals::OrderedDict{String, Any}

    function ContextLabel(vals::AbstractDict; __checktype = true)
        __checktype && foreach(_check_contextlabel, vals) # check
        return new(vals)
    end
    function ContextLabel(vals::Vector; __checktype = true, __checkunique = true)
        __checktype && foreach(_check_contextlabel, vals) # check
        __checkunique && _check_unique_keys(vals) # check
        return new(_datoddict(vals))
    end
    ContextLabel(ctx::ContextLabel) = ctx
    ContextLabel() = ContextLabel([])
end
