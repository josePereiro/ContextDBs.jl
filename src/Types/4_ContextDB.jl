## ------------------------------------------------------------------
struct ContextDB
    data::OrderedDict{UInt, Context}
    ctx::Context  # current context
    extras::Dict
    ContextDB(data, ctx, extras) = new(data, ctx, extras)
    ContextDB(db::ContextDB, data::OrderedDict) = new(data, db.ctx, db.extras)
    ContextDB() = new(OrderedDict(), Context(["ROOT"]), Dict())
end

## ------------------------------------------------------------------
import Base.show
function show(io::IO, db::ContextDB)
    println(io, "ContextDB with ", length(db.data), " contexts")
end
