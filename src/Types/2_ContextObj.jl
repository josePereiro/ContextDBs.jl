## ------------------------------------------------------------------
# An storage optimized for Querying
# TODO: Rename to ContextObj
struct ContextObj
    label::OrderedDict{String, Any}
    data::OrderedDict{String, Any}
    ContextObj(l::ContextLabel) = new(OrderedDict(l.vals), OrderedDict())
    ContextObj(lv::Vector) = ContextObj(ContextLabel(lv))
end

