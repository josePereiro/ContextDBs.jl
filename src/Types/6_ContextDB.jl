## ------------------------------------------------------------------
struct ContextDB
    data::OrderedDict{UInt, Entry}
    extras::Dict
    ContextDB(data, extras) = new(data, extras)
    ContextDB() = new(OrderedDict(), Dict())
end

## ------------------------------------------------------------------
import Base.show
function show(io::IO, db::ContextDB)
    println(io, "ContextDB with ", length(db.data), " contexts")
end
