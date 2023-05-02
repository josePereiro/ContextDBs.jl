## ------------------------------------------------------------------
# BUILDING
## ------------------------------------------------------------------

## ------------------------------------------------------------------
_TAGDB_OBJ_KEY_ALLOWED_TYPES = [String]

for T in _TAGDB_OBJ_KEY_ALLOWED_TYPES
    @eval _check_tagdb_obj_key(::$T) = nothing
end

_check_tagdb_obj_key(k) = _check_error("Context data key", k, _TAGDB_OBJ_KEY_ALLOWED_TYPES)

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
# OUTPUT
## ------------------------------------------------------------------

import Base.getindex
function getindex(e::Context, k::String)
    haskey(e.label, k) && return e.label[k]
    return e.data[k]
end

## ------------------------------------------------------------------
# INPUT
## ------------------------------------------------------------------
function _setindex!(e::Context, v, k::String)
    haskey(e.label, k) && error("The context keys are reserved. key: $(k)")
    setindex!(e.data, v, k)
end

function setval!(e::Context, vals::Vector)
    for val in vals
        _check_tagdb_obj(val)
        _setindex!(e, _datval(val), _datkey(val))
    end
    return e
end

## ------------------------------------------------------------------
# UTILS
## ------------------------------------------------------------------
import Base.haskey
haskey(e::Context, k::String) = haskey(e.label, k) || haskey(e.data, k)

import Base.show
function show(io::IO, e::Context)
    println(io, "Context")
    
    print(io, " label      ")
    _print_kval(io, e.label)
    println(io)

    print(io, " data       ")
    _print_ktype(io, e.data)
    println(io)
end
