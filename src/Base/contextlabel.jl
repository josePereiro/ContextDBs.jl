## ------------------------------------------------------------------
# BUILDING
## ------------------------------------------------------------------

# The reduce allowed types are to help hygine
_CONTEXTLABEL_KEY_ALLOWED_TYPES = [String]

for T in _CONTEXTLABEL_KEY_ALLOWED_TYPES
    @eval _check_contextlabel_key(::$T) = nothing
end

_check_contextlabel_key(k) = _check_error("context label key", k, _CONTEXTLABEL_KEY_ALLOWED_TYPES)

## ------------------------------------------------------------------
# The reduce allowed types are to help hygine
_CONTEXTLABEL_VAL_ALLOWED_TYPES = [String, Bool, Int, Float64, Symbol, DateTime, VersionNumber, Nothing]

for T in _CONTEXTLABEL_VAL_ALLOWED_TYPES
    @eval _check_contextlabel_val(::$T) = nothing
end

_check_contextlabel_val(v) = _check_error("context val", v, _CONTEXTLABEL_VAL_ALLOWED_TYPES)

## ------------------------------------------------------------------
function _check_contextlabel(val::Pair)
    k, v = val
    _check_contextlabel_key(k)
    _check_contextlabel_val(v)
    return nothing
end
_check_contextlabel(val) = _check_contextlabel_key(val)

## ------------------------------------------------------------------
# BASE
## ------------------------------------------------------------------
import Base.show
function show(io::IO, l::ContextLabel)
    print(io, "ContextLabel ")
    _print_kval(io, l.vals)
end

import Base.hash
# The order of the context labels should not matter hash(["BLA", "BLO" => 1]) == hash(["BLO" => 1, "BLA"])
function hash(l::ContextLabel, h::UInt)
    h = hash(:ContextLabel, h)
    for v in l.vals
        h += hash(v)
    end
    return h
end
hash(l::ContextLabel, i::Int) = hash(l, UInt(i))
hash(l::ContextLabel) = hash(l, 0)

import Base.getindex
getindex(l::ContextLabel, k::String) = l.vals[k]

## ------------------------------------------------------------------
# INPUT
## ------------------------------------------------------------------
function _unsafe_setlabel!(l::ContextLabel, val) 
    setindex!(l.vals, _datval(val), _datkey(val))
    return l
end

# function set!(l::ContextLabel, val) 
#     _check_contextlabel(val)
#     _unsafe_setlabel!(l, val)
#     return l
# end

## ------------------------------------------------------------------
import Base.push!
function _unsafe_push!(l::ContextLabel, val)
    k = _datkey(val)
    haskey(l, k) && error("Pushing existing key is not allowed, key: ", k)
    _unsafe_setlabel!(l, val)
    return l
end

# function push!(l::ContextLabel, val)
#     _check_contextlabel(val)
#     _unsafe_push!(l, val)
#     return l
# end

## ------------------------------------------------------------------
# UTILS
## ------------------------------------------------------------------
function _hash_vector(l::ContextLabel)
    vec = [hash(val) for val in l.vals]
    sort!(vec)
    return vec
end

function _find_key(l::ContextLabel, k0::String)
    for (i, k) in enumerate(keys(l.vals))
        k == k0 && return i
    end
    return nothing
end

function _find_key_err(l::ContextLabel, k0)
    i = _find_key(l, k0)
    isnothing(i) && error("ContextLabel key not found, key: ", k0)
    return i
end

## ---------------------------------------------------------------------
## CONTEXT HANDLING
## ---------------------------------------------------------------------
function _delfrom!(l::ContextLabel, k0)
    found = false
    for k in keys(l.vals)
        if found
            delete!(l.vals, k)
        else
            found = k == k0
        end
    end
    return found
end

function _build_qkvec(l::ContextLabel, qkvec::Vector)
    
    kvec = []
    
    # Handle primer
    k0 = first(qkvec)
    isa(k0, String) || error("ContextLabel primer must be a String, kvec: ", qkvec)
    i0 = _find_key_err(l, k0)
    for (i, val) in enumerate(l.vals)
        push!(kvec, val)
        i == i0 && break
    end

    # Add rest
    for (i, val) in enumerate(qkvec)
        i == 1 && continue
        push!(kvec, val)
    end
    
    return kvec
end

# ## ------------------------------------------------------------------
# # CLEAR
# ## ------------------------------------------------------------------

# function _clearcontext!(l::ContextLabel, r::AbstractArray)
#     ks_ = collect(keys(l.vals))[r]
#     foreach(ks_) do k
#         delete!(l.vals, k)
#     end
#     return l
# end

# clearcontext!(l::ContextLabel) = (empty!(l.vals); l)
# clearcontext!(l::ContextLabel, ::Colon) = clearcontext!(l)

# function clearcontext!(l::ContextLabel, k::String, offset::Int = 0) 
#     i = _find_key_err(l, k) + offset
#     _clearcontext!(l, [i])
# end

# # k:(end + offset)
# function clearcontext!(l::ContextLabel, k::String, ::Colon, offset::Int = 0)
#     r = _find_key_err(l, k):(length(l.vals) + offset)
#     _clearcontext!(l, r)
# end

# # (k + offset):(end + offset)
# function clearcontext!(l::ContextLabel, k::String, offset0::Int, ::Colon, offset1::Int = 0)
#     r = (_find_key_err(l, k) + offset0):(length(l.vals) + offset1)
#     _clearcontext!(l, r)
# end

# # (1 + offset):(end + offset)
# function clearcontext!(l::ContextLabel, offset0::Int, ::Colon, offset1::Int)
#     r = (1 + offset0):(length(l.vals) + offset1)
#     _clearcontext!(l, r)
# end

# # 1:(k + offset)
# function clearcontext!(l::ContextLabel, ::Colon, k::String, offset::Int = 0)
#     r = 1:(_find_key_err(l, k) + offset)
#     _clearcontext!(l, r)
# end

# ## ------------------------------------------------------------------
