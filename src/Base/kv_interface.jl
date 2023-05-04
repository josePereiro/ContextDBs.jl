## ------------------------------------------------------------------
# kw vec interface
_datkey(p::Pair) = first(p)
_datkey(k::String) = k 
_datkey(p) = p

_datval(p::Pair) = last(p)
_datval(::String) = :__NOVAL
_datval(p) = p # for general objects

_datdict(vals::Vector) = Dict(_datkey(v) => _datval(v) for v in vals)
_datoddict(vals::Vector) = OrderedDict(_datkey(v) => _datval(v) for v in vals)

function _datkvec(vals...; kwargs...)
    vec = Any[]
    for val in vals
        push!(vec, val)
    end
    for val in kwargs
        push!(vec, string(_datkey(val)) => _datval(val))
    end
    return vec
end

_datkvec(vals::AbstractDict) = Any[_datkey(v) => _datval(v) for v in vals]

function _compact_kvec!(kval::Vector)
    for (i, kv) in enumerate(kval)
        _datval(kv) == :__NOVAL || continue
        kval[i] = _datkey(kv)
    end
    kval
end