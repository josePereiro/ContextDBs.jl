## ------------------------------------------------------------------
_check_error(msg::String, v, allowed::Vector) = error(
    "Invalid ", msg, ".\n\t",
    "got      ", v, "::", typeof(v), "\n\t", 
    "expected Union{", join(allowed, ", "), "}",
)

## ------------------------------------------------------------------
# kw vec interface
_datkey(k::String) = k
_datkey(p::Pair) = first(p)

_datval(s::String) = s
_datval(p::Pair) = last(p)
_datval(p) = p

_datdict(vals::Vector) = Dict(_datkey(v) => _datval(v) for v in vals)
_datoddict(vals::Vector) = OrderedDict(_datkey(v) => _datval(v) for v in vals)

## ------------------------------------------------------------------
function _check_unique_keys(vals)
    length(Set(_datkey(val)::String for val in vals)) == length(vals) || error("Context/Query duplicated keys")
    return nothing
end

## ------------------------------------------------------------------
# It assumes the to sets/vec iterates ordered
function _issubset_sorted(sub, super)    
    superi = firstindex(super)
    super1 = lastindex(super)
    for subx in sub
        while true
            superx = super[superi]
            superi = nextind(super, superi)
            subx == superx && break
            superi > super1 && return false
        end
    end
    return true
end

## ------------------------------------------------------------------
function _kTDict(kT::DataType, d0::Dict)
    _new = Dict{kT, valtype(d0)}()
    for (k, v) in d0
        _new[kT(k)] = v
    end
    return _new
end

## ------------------------------------------------------------------
# @context var
# @context var1 = val
# @context key => val
# @context var1 var2
