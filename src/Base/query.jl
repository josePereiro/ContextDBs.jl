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
## QUERYING
## ------------------------------------------------------------------

# ------------------------------------------------------------------
function query(f::Function, db::ContextDB, qv::Vector)
    found = nothing
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
    found = OrderedDict{UInt, Entry}()
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
## UTILS
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

function _obj_match(obj::Entry, q)
    _obj_match(obj.ctx, q) && return true
    _obj_match(obj.data, q) && return true
    return false
end

# A tuple must match all elms
function _obj_match(obj::Entry, qs::Tuple)
    for qi in qs
        _obj_match(obj, qi) || return false
    end
    return true
end

function _obj_match(obj::Entry, q::Query)
    for qi in q.vals
        _obj_match(obj, qi) || return false
    end
    return true
end

_obj_match(obj::Entry, c::Context) = _obj_match(obj, Query(c))