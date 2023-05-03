## ------------------------------------------------------------------
struct ContextDB
    
    data::OrderedDict{UInt, ContextObj}     # commited data
    label::ContextLabel                  # current context label
    stage::OrderedDict{String, Any}      # current uncommited data
    extras::Dict                         # utils

    ContextDB(data, label, stage, extras) = new(data, label, stage, extras)
    ContextDB(db::ContextDB, data::OrderedDict) = new(data, db.label, db.stage, db.extras)
    ContextDB() = new(OrderedDict(), ContextLabel(["ROOT"]), OrderedDict(), Dict())
end


