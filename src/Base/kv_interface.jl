## ------------------------------------------------------------------
# kw vec interface
_datkey(k::String) = k
_datkey(p::Pair) = first(p)

_datval(s::String) = s
_datval(p::Pair) = last(p)
_datval(p) = p

_datdict(vals::Vector) = Dict(_datkey(v) => _datval(v) for v in vals)
_datoddict(vals::Vector) = OrderedDict(_datkey(v) => _datval(v) for v in vals)

function _datkvec(vals...; kwargs...)
    vec = []
    for val in vals
        push!(vec, _datkey(val) => _datval(val))
    end
    for val in kwargs
        push!(vec, string(_datkey(val)) => _datval(val))
    end
    return vec
end