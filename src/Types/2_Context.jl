## ------------------------------------------------------------------
# An storage optimized for Querying
struct Context
    label::OrderedDict{String, Any}
    data::OrderedDict{String, Any}
    Context(l::ContextLabel) = new(OrderedDict(l.vals), OrderedDict())
    Context(lv::Vector) = Context(ContextLabel(lv))
end

