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

function context!(db::ContextDB, ctxv::Vector)
    
    # some checks
    isempty(ctxv) && return db.ctx
    foreach(_check_context, ctxv)

    # use primer
    found = _delfrom!(db.ctx, _datkey(first(ctxv)))
    
    # set!
    for (i, val) in enumerate(ctxv)
        found && i == 1 && _datval(val) === :__NOVAL && continue # ignore key only primer
        _unsafe_set!(db.ctx, val)
    end
    
    return db.ctx
end

## ---------------------------------------------------------------------
function emptycontext!(db::ContextDB)
    empty!(db.ctx.vals)
    context!(db, ["ROOT"])
    return db.ctx
end

## ---------------------------------------------------------------------
# Stash context away
function savecontext!(db::ContextDB, k::String)
    store = get!(db.extras, :CTX_STORE) do 
        Dict{String, Context}()
    end
    store[k] = deepcopy(db.ctx)
    return db.ctx
end

# TODO: Do stash (a dict that store key => contexts)
function loadcontext!(db::ContextDB, k::String, del::Bool = false)
    store = get!(db.extras, :CTX_STORE) do 
        Dict{String, Context}()
    end
    emptycontext!(db)
    merge!(db.ctx.vals, store[k].vals)
    del && delete!(store, k)
    return db.ctx
end

## ---------------------------------------------------------------------
function tempcontext(f::Function, db::ContextDB, ctxv::Vector)
    _cache_id = string(time())
    try
        savecontext!(db, _cache_id)
        context!(db, ctxv)
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

getval(f::Function, db::ContextDB) = get(f, db.data, hash(db.ctx))
getval(f::Function, db::ContextDB, ctxv::Vector) = tempcontext(db, ctxv) do 
    return getval(f, db)
end

getval(db::ContextDB, ctx::Vector) = getval(db, ctx) do
    error("Context not found\n", db.ctx)
end
getval(db::ContextDB) = getval(db) do
    error("Context not found\n", db.ctx)
end

## ---------------------------------------------------------------------
# INPUT

function setval!(db::ContextDB, vals::Vector)
    en = getval(db) do 
        db.data[hash(db.ctx)] = Entry(db.ctx)
    end
    setval!(en, vals)
    return en
end

setval!(db::ContextDB, ctxv::Vector, vals::Vector) = tempcontext(db, ctxv) do
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