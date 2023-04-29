## ------------------------------------------------------------------
# An object optimized to be hashable and pushable
struct Context
    vals::OrderedDict{String, Any}

    function Context(vals::AbstractDict; __checktype = true)
        __checktype && foreach(_check_context, vals) # check
        return new(vals)
    end
    function Context(vals::Vector; __checktype = true, __checkunique = true)
        __checktype && foreach(_check_context, vals) # check
        __checkunique && _check_unique_keys(vals) # check
        return new(_datoddict(vals))
    end
    Context(ctx::Context) = ctx
    Context() = Context([])
end
