## ------------------------------------------------------------------
# BUILDING
## ------------------------------------------------------------------

## ------------------------------------------------------------------
_TAGDB_OBJ_KEY_ALLOWED_TYPES = [String]

for T in _TAGDB_OBJ_KEY_ALLOWED_TYPES
    @eval _check_tagdb_obj_key(::$T) = nothing
end

_check_tagdb_obj_key(k) = _check_error("Entry data key", k, _TAGDB_OBJ_KEY_ALLOWED_TYPES)

## ------------------------------------------------------------------
# All allowed
_check_tagdb_obj_val(k) = nothing

## ------------------------------------------------------------------
function _check_tagdb_obj(val::Pair)
    k, v = val
    _check_tagdb_obj_key(k)
    _check_tagdb_obj_val(v)
    return nothing
end
_check_tagdb_obj(val) = _check_tagdb_obj_key(val)


## ------------------------------------------------------------------
# BASE
## ------------------------------------------------------------------
import Base.getindex
function getindex(e::Entry, k::String)
    haskey(e.ctx, k) && return e.ctx[k]
    return e.data[k]
end

function _setindex!(e::Entry, v, k::String)
    haskey(e.ctx, k) && error("The context keys are reserved. key: $(k)")
    setindex!(e.data, v, k)
end

import Base.show
function show(io::IO, e::Entry)
    println(io, "Entry")
    println(io, " context    ", e.ctx)
    println(io, " data       ", e.data)
end

## ------------------------------------------------------------------
# INPUT
## ------------------------------------------------------------------
function set!(e::Entry, ds...; kwds...) 
    for d in ds
        _check_tagdb_obj(d)
        _setindex!(e, _datval(d), _datkey(d))
    end
    for (k, v) in kwds
        _setindex!(e, v, string(k))
    end
    return e
end

set!(e::Entry, ds::Vector) = set!(e, ds...)