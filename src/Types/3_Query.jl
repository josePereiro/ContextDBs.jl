## ------------------------------------------------------------------
struct Query
    vals::Dict
    function Query(vals::AbstractDict; __checktype = true)
        __checktype && foreach(_check_query, vals) # check
        return new(vals)
    end
    function Query(vals::Vector; __checktype = true, __checkunique = true)
        __checkunique && _check_unique_keys(vals)
        return Query(_datdict(vals); __checktype)
    end
end
