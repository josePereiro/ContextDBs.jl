## ------------------------------------------------------------------
## BUILDING
## ------------------------------------------------------------------

## ------------------------------------------------------------------
_KEY_QUERY_ALLOWED_TYPES = [String, Function, Regex]

for T in _KEY_QUERY_ALLOWED_TYPES
    @eval _check_key_query(::$T) = nothing
end

_check_key_query(k) = _check_error("key query", k, _KEY_QUERY_ALLOWED_TYPES)

## ------------------------------------------------------------------
# The rest of the types are handled using a Function
_VAL_QUERY_ALLOWED_TYPES = [String, Regex, Bool, Number, Symbol, DateTime, VersionNumber, Function]

for T in _VAL_QUERY_ALLOWED_TYPES
    @eval _check_val_query(::$T) = nothing
end

_check_val_query(v) = _check_error("val query", v, _VAL_QUERY_ALLOWED_TYPES)

## ------------------------------------------------------------------
function _check_query(val::Pair)
    k, v = val
    _check_key_query(k)
    _check_val_query(v)
    return nothing
end
_check_query(val) = _check_key_query(val)


## ------------------------------------------------------------------
# PRODUCT
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
## QUERYING
## ------------------------------------------------------------------

# ------------------------------------------------------------------
function query(f::Function, db::ContextDB, qv::Vector)
    # integrate context
    found = nothing
    qv = _build_query_kvec(db.ctx.label, qv)
    pq = ProductQuery(qv)
    for q in pq.qs # for each query
        for (h, obj) in db.data # for each obj
            if _obj_match(obj, q) 
                isnothing(found) || error("The query do not solve an unique entry. See 'queryall'")
                found = obj
            end
        end
    end
    return isnothing(found) ? f() : found
end
query(f::Function, db::ContextDB, q, qs...) = query(f, db, _datkvec(q, qs...))

query(db::ContextDB, qv::Vector) = query(db, qv) do 
    error("The query do not solve any entry")
end
query(db::ContextDB, q, qs...) = query(db, _datkvec(q, qs...))

# ------------------------------------------------------------------
function queryall(db::ContextDB, qv::Vector)
    isempty(db.data) && return db
    found = OrderedDict{UInt, ContextObj}()
    qv = _build_query_kvec(db.ctx.label, qv)
    pq = ProductQuery(qv)
    # TODO: make more efficient
    for q in pq.qs # for each query
        for (h, obj) in db.data # for each obj
            if _obj_match(obj, q)
                setindex!(found, obj, h)
            end
        end
    end
    isempty(found) && error("The query/context do not match any entry.")
    return ContextDB(db, found)
end
queryall(db::ContextDB, q, qs...) = queryall(db, _datkvec(q, qs...))

## ------------------------------------------------------------------
## MATCHING
## ------------------------------------------------------------------

# ------------------------------------------------------------------
# Atomic matching
_ismatch(f::Function, y) = f(y) === true
_ismatch(y, f::Function) = _ismatch(f, y)
# _ismatch('A', "A") = true, this allows to use 'A':'B'
_ismatch(x::AbstractChar, y::AbstractString) = isequal(string(x), y)
_ismatch(x::AbstractString, y::AbstractChar) = _ismatch(y, x)
_ismatch(r::Regex, y::String) = !isnothing(match(r, y))
_ismatch(r::Regex, y) = _ismatch(r, string(y))
_ismatch(y, r::Regex) = _ismatch(r, y)
_ismatch(x, y) = isequal(x, y)
_ismatch(x) = Base.Fix1(_ismatch, x)

# Obj, Query val matching
# A pair must match both
function _obj_match(vals::AbstractDict, p::Pair)
    kq, vq = p
    for val in vals
        _ismatch(_datkey(val), kq) || continue
        _ismatch(_datval(val), vq) && return true
    end
    return false
end

# A non pair is assume to match only keys
function _obj_match(vals::AbstractDict, q)
    for k in keys(vals)
        _ismatch(k, q) && return true
    end
    return false
end

function _obj_match(c::ContextObj, qi)
    _obj_match(c.label, qi) && return true
    _obj_match(c.data, qi) && return true
    return false
end

# A tuple must match all elms
function _obj_match(c::ContextObj, qs::Tuple)
    for qi in qs
        _obj_match(c, qi) || return false
    end
    return true
end

## ------------------------------------------------------------------
# UTILS
## ------------------------------------------------------------------

import Base.show
function show(io::IO, ::ProductQuery)
    println(io, "ProductQuery")
end