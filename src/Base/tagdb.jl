## ------------------------------------------------------------------
# OUTPUT
## ------------------------------------------------------------------
import Base.get
# Select an object from a context
get(f::Function, db::ContextDB, c) = get(f, db.data, hash(Context(c)))
get(db::ContextDB, c) = get(db, c) do
    error("Context not found\n", Context(c))
end
get(db::ContextDB, c::Context, dflt)  = get(() -> dflt, db, c)
get(db::ContextDB, c::Vector, dflt) = get(db, Context(c), dflt)


# TODO: Add the query version

## ------------------------------------------------------------------
# INPUT
## ------------------------------------------------------------------
function _set!(db::ContextDB, c, vals...; kwargs...)
    c = Context(c)
    en = get(db, c) do
        db.data[hash(c)] = Entry(c)
    end
    # set stuff
    set!(en, vals...; kwargs...)
    return en
end
set!(db::ContextDB, c, vals...; kwargs...) = (_set!(db, c, vals...; kwargs...); db)

import Base.get!
get!(db::ContextDB, c, vals...; kwargs...) = get(db, c) do 
    return _set!(db, c, vals...; kwargs...)
end

get!(f::Function, db::ContextDB, c) = get(db, c) do 
    vals = f()
    isa(vals, Vector) || error("The function should returns a Vector")
    return _set!(db, c, vals)
end

## ------------------------------------------------------------------
# BASE
## ------------------------------------------------------------------
import Base.empty!
empty!(db::ContextDB) = empty!(db.data)