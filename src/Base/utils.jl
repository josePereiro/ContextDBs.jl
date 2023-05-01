## ------------------------------------------------------------------
_check_error(msg::String, v, allowed::Vector) = error(
    "Invalid ", msg, ".\n\t",
    "got      ", v, "::", typeof(v), "\n\t", 
    "expected Union{", join(allowed, ", "), "}",
)

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
function _print_kval(io::IO, vals)
    for val in vals
        print(io, _datkey(val), " => ", _datval(val), ", ")
    end
end

function _print_ktype(io::IO, vals)
    for val in vals
        print(io, _datkey(val), " => ::", typeof(_datval(val)), ", ")
    end
end

## ------------------------------------------------------------------
function _kTDict(kT::DataType, d0::Dict)
    _new = Dict{kT, valtype(d0)}()
    for (k, v) in d0
        _new[kT(k)] = v
    end
    return _new
end

