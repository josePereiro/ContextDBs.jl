## ------------------------------------------------------------------
struct ProductQuery
    qs::Iterators.ProductIterator
    function ProductQuery(vals::Vector; __checktype = true, __checkunique = true)
        qs = _tags_product(vals)
        for q in qs
            # __checkunique && _check_unique_keys(q)
            __checktype && foreach(_check_query, q)
        end
        return new(qs)
    end
end