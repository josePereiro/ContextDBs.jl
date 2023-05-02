## ---------------------------------------------------------------------
## UNCONTEXTUALIZED INDEXING
## ---------------------------------------------------------------------
import Base.getindex
getindex(db::ContextDB, i::UInt64) = db.data[i]
getindex(db::ContextDB, i) = db.data.vals[i]

# Error version
getindex(db::ContextDB, ::typeof(!), k::String) = [obj[k] for (h, obj) in db.data]

# Error free
getindex(db::ContextDB, ::Colon, k::String) = [obj[k] for (h, obj) in db.data if haskey(obj, k)]

## ---------------------------------------------------------------------
## CONTEXT HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# GETTER
context(db::ContextDB) = db.ctx

## ---------------------------------------------------------------------
# SETTER

function context!(db::ContextDB, labv::Vector)
    
    # some checks
    isempty(labv) && return db.ctx.label
    foreach(_check_contextlabel, labv)

    # use primer
    found = _delfrom!(db.ctx.label, _datkey(first(labv)))
    
    # set!
    for (i, val) in enumerate(labv)
        found && i == 1 && _datval(val) === :__NOVAL && continue # ignore key only primer
        _unsafe_setlabel!(db.ctx.label, val)
    end
    
    return db.ctx.label
end

## ---------------------------------------------------------------------
function emptycontext!(db::ContextDB)
    empty!(db.ctx.label.vals)
    empty!(db.ctx.data)
    context!(db, ["ROOT"])
    return db.ctx
end

## ---------------------------------------------------------------------
# Stash context away
function savecontext!(db::ContextDB, k::String)
    store = get!(db.extras, :CTX_STORE) do 
        Dict{String, ContextLabel}()
    end
    store[k] = deepcopy(db.ctx.label)
    return db.ctx.label
end

# TODO: Do stash (a dict that store key => contexts)
function loadcontext!(db::ContextDB, k::String, del::Bool = false)
    store = get!(db.extras, :CTX_STORE) do 
        Dict{String, ContextLabel}()
    end
    emptycontext!(db)
    merge!(db.ctx.label.vals, store[k].vals)
    del && delete!(store, k)
    return db.ctx.label
end

## ---------------------------------------------------------------------
function tempcontext(f::Function, db::ContextDB, labv::Vector)
    _cache_id = string(time())
    try
        savecontext!(db, _cache_id)
        context!(db, labv)
        return f()
    finally
        loadcontext!(db, _cache_id, true)
    end
end

## ---------------------------------------------------------------------
## DATA HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# OUTPUT
# Select an object from a context

getval(f::Function, db::ContextDB) = get(f, db.data, hash(db.ctx.label))
getval(f::Function, db::ContextDB, labv::Vector) = tempcontext(db, labv) do 
    return getval(f, db)
end

getval(db::ContextDB, ctx::Vector) = getval(db, ctx) do
    error("ContextLabel not found\n", db.ctx.label)
end
getval(db::ContextDB) = getval(db) do
    error("ContextLabel not found\n", db.ctx.label)
end

## ---------------------------------------------------------------------
# INPUT

function setval!(db::ContextDB, vals::Vector)
    en = getval(db) do 
        db.data[hash(db.ctx.label)] = Context(db.ctx.label)
    end
    setval!(en, vals)
    return en
end

setval!(db::ContextDB, labv::Vector, vals::Vector) = tempcontext(db, labv) do
    setval!(db, vals)
end

## ---------------------------------------------------------------------
## UTILS
## ---------------------------------------------------------------------

import Base.isempty
isempty(db::ContextDB) = isempty(db.data)

import Base.lastindex
lastindex(db::ContextDB) = lastindex(db.data.vals)

import Base.firstindex
firstindex(db::ContextDB) = firstindex(db.data.vals)

import Base.length
length(db::ContextDB) = length(db.data.vals)

function dbcontexts(io::IO, db::ContextDB)
    contexts = Set([])
    for en in values(db.data)
        push!(contexts, _ktype_vec(en.label))
    end
    # print
    for vals in contexts
        print(io, "[")
        for p in vals
            k, val = _datkey(p), _datval(p)
            if val === :__NOVAL; print(io, repr(k), ", ")
                else; print(io, repr(k), " => ::", repr(val), ", ")
            end
        end
        println(io, "]")
    end
end

dbcontexts(db::ContextDB) = dbcontexts(stdout, db)