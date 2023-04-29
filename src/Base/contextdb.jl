## ---------------------------------------------------------------------
## UNCONTEXTUALIZED INDEXING
## ---------------------------------------------------------------------
import Base.getindex
getindex(db::ContextDB, i::UInt64) = db.data[i]
getindex(db::ContextDB, i) = db.data.vals[i]

import Base.lastindex
lastindex(db::ContextDB) = lastindex(db.data.vals)

import Base.firstindex
firstindex(db::ContextDB) = firstindex(db.data.vals)

import Base.length
length(db::ContextDB) = length(db.data.vals)

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

    # del from first
    delfrom!(db.ctx, _datkey(first(ctxv)))
    
    # set!
    for val in ctxv
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
function loadcontext!(db::ContextDB, k::String)
    store = get!(db.extras, :CTX_STORE) do 
        Dict{String, Context}()
    end
    emptycontext!(db)
    merge!(db.ctx.vals, store[k].vals)
    return db.ctx
end

## ---------------------------------------------------------------------
function tempcontext(f::Function, db::ContextDB, ctxv::Vector)
    try
        savecontext!(db, "__WITHCONTEXT_CACHE__")
        context!(db, ctxv)
        return f()
    finally
        loadcontext!(db, "__WITHCONTEXT_CACHE__")
    end
end

## ---------------------------------------------------------------------
## DATA HANDLING
## ---------------------------------------------------------------------

## ------------------------------------------------------------------
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

## ------------------------------------------------------------------
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

