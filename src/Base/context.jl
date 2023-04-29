## ------------------------------------------------------------------
# BUILDING
## ------------------------------------------------------------------

# The reduce allowed types are to help hygine
_CONTEXT_KEY_ALLOWED_TYPES = [String]

for T in _CONTEXT_KEY_ALLOWED_TYPES
    @eval _check_context_key(::$T) = nothing
end

_check_context_key(k) = _check_error("context key", k, _CONTEXT_KEY_ALLOWED_TYPES)

## ------------------------------------------------------------------
# The reduce allowed types are to help hygine
_CONTEXT_VAL_ALLOWED_TYPES = [String, Bool, Int, Float64, Symbol, DateTime, VersionNumber, Nothing]

for T in _CONTEXT_VAL_ALLOWED_TYPES
    @eval _check_context_val(::$T) = nothing
end

_check_context_val(v) = _check_error("context val", v, _CONTEXT_VAL_ALLOWED_TYPES)

## ------------------------------------------------------------------
function _check_context(val::Pair)
    k, v = val
    _check_context_key(k)
    _check_context_val(v)
    return nothing
end
_check_context(val) = _check_context_key(val)

## ------------------------------------------------------------------
# BASE
## ------------------------------------------------------------------
import Base.show
function show(io::IO, c::Context)
    print(io, "Context [")
    for (k, val) in c.vals
        print(io, k, " => ", val, ", ")
    end
    print(io, "]")
end

# import Base.length
# length(c::Context) = length(c.vals)

import Base.hash
function hash(c::Context, h::UInt)
    h = hash(:Context, h)
    for v in c.vals
        h = hash(v, h)
    end
    return h
end
hash(c::Context, i::Int) = hash(c, UInt(i))
hash(c::Context) = hash(c, 0)

## ------------------------------------------------------------------
# INPUT
## ------------------------------------------------------------------
function _unsafe_set!(c::Context, val) 
    setindex!(c.vals, _datval(val), _datkey(val))
    return c
end

function set!(c::Context, val) 
    _check_context(val)
    _unsafe_set!(c, val)
    return c
end

## ------------------------------------------------------------------
import Base.push!
function _unsafe_push!(c::Context, val)
    k = _datkey(val)
    haskey(c, k) && error("Pushing existing key is not allowed, key '$k'. See set!")
    _unsafe_set!(c, val)
    return c
end

function push!(c::Context, val)
    _check_context(val)
    _unsafe_push!(c, val)
    return c
end

# ## ------------------------------------------------------------------
# import Base.Dict
# Dict(c::Context) = Dict(c.vals)

# import OrderedCollections.OrderedDict
# OrderedDict(c::Context) = OrderedDict(c.vals)

# ## ------------------------------------------------------------------
# # CONTRUCTORS
# ## ------------------------------------------------------------------
# Context(c::Context) = c
# # Context(q::Query) = Context(q.vals; __checktype = true, __checkunique = false)

## ------------------------------------------------------------------
# UTILS
## ------------------------------------------------------------------
function _hash_vector(c::Context)
    vec = [hash(val) for val in c.vals]
    sort!(vec)
    return vec
end

function _find_key(c::Context, k0::String)
    for (i, k) in enumerate(keys(c.vals))
        k == k0 && return i
    end
    return nothing
end

function _find_key_err(c::Context, k0)
    i = _find_key(c, k0)
    isnothing(i) && error("Context key not found, key: ", k0)
    return i
end

## ---------------------------------------------------------------------
## CONTEXT HANDLING
## ---------------------------------------------------------------------
function delfrom!(ctx::Context, k0)
    found = false
    for k in keys(ctx.vals)
        if found
            delete!(ctx.vals, k)
            continue
        end
        found = k == k0
    end
    return nothing
end

# ## ------------------------------------------------------------------
# # CLEAR
# ## ------------------------------------------------------------------

# function _clearcontext!(c::Context, r::AbstractArray)
#     ks_ = collect(keys(c.vals))[r]
#     foreach(ks_) do k
#         delete!(c.vals, k)
#     end
#     return c
# end

# clearcontext!(c::Context) = (empty!(c.vals); c)
# clearcontext!(c::Context, ::Colon) = clearcontext!(c)

# function clearcontext!(c::Context, k::String, offset::Int = 0) 
#     i = _find_key_err(c, k) + offset
#     _clearcontext!(c, [i])
# end

# # k:(end + offset)
# function clearcontext!(c::Context, k::String, ::Colon, offset::Int = 0)
#     r = _find_key_err(c, k):(length(c.vals) + offset)
#     _clearcontext!(c, r)
# end

# # (k + offset):(end + offset)
# function clearcontext!(c::Context, k::String, offset0::Int, ::Colon, offset1::Int = 0)
#     r = (_find_key_err(c, k) + offset0):(length(c.vals) + offset1)
#     _clearcontext!(c, r)
# end

# # (1 + offset):(end + offset)
# function clearcontext!(c::Context, offset0::Int, ::Colon, offset1::Int)
#     r = (1 + offset0):(length(c.vals) + offset1)
#     _clearcontext!(c, r)
# end

# # 1:(k + offset)
# function clearcontext!(c::Context, ::Colon, k::String, offset::Int = 0)
#     r = 1:(_find_key_err(c, k) + offset)
#     _clearcontext!(c, r)
# end

# ## ------------------------------------------------------------------
