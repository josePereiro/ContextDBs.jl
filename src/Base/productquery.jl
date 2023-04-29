## ------------------------------------------------------------------
# BUILDING
## ------------------------------------------------------------------

## ------------------------------------------------------------------
# Product
# Char -> Vector{String}
_factor_format(x::AbstractChar) = String[string(x)]
# String -> Vector{String}
_factor_format(x::AbstractString) = String[string(x)]
# Pair
function _factor_format(p::Pair)
    k, v = _factor_format(first(p)), _factor_format(last(p)) 
    return Pair[k => v for (k, v) in Iterators.product(k, v)]
end
# Arrays are broadcateds
_factor_format(x::AbstractArray) = x

# callback
_factor_format(x) = typeof(x)[x]

function _tags_product(tags...)
    tags = collect(Any, tags)
    
    # handle types
    for (i, t) in enumerate(tags)
        tags[i] = _factor_format(t)
    end
    
    return Iterators.product(tags...)
end

_tags_product(tags::Vector) = _tags_product(tags...)

## ------------------------------------------------------------------
# CONTRUCTURS
## ------------------------------------------------------------------

## ------------------------------------------------------------------
ProductQuery(q::ProductQuery) = q
ProductQuery(q::Query) = ProductQuery(q.vals; __checktype = false, __checkunique = false)
ProductQuery(c::Context) = ProductQuery(c.vals; __checktype = false, __checkunique = false)

## ------------------------------------------------------------------
# UTILS
## ------------------------------------------------------------------

import Base.show
function show(io::IO, ::ProductQuery)
    println(io, "ProductQuery")
end