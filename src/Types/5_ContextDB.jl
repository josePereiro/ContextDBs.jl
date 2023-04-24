## ------------------------------------------------------------------
struct ContextDB
    data::Dict{UInt, Entry}
    extras::Dict
    ContextDB() = new(Dict(), Dict())
end

## ------------------------------------------------------------------
import Base.show
function show(io::IO, db::ContextDB)
    println(io, "ContextDB with ", length(db.data), " contexts")
end
