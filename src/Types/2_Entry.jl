## ------------------------------------------------------------------
# An storage optimized for Querying
struct Entry
    ctx::Dict{String, Any}
    data::Dict{String, Any}
    Entry(c::Context) = new(Dict(c), Dict())
end

## ------------------------------------------------------------------
