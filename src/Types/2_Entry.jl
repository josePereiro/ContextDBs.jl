## ------------------------------------------------------------------
# An storage optimized for Querying
struct Entry
    ctx::OrderedDict{String, Any}
    data::OrderedDict{String, Any}
    Entry(c::Context) = new(OrderedDict(c.vals), OrderedDict())
end

