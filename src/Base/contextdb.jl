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
## CONTEXT LABEL HANDLING
## ---------------------------------------------------------------------

contextlabel(db::ContextDB) = db.label

## ---------------------------------------------------------------------
# SETTER

function context!(db::ContextDB, labv::Vector)
    
    # some checks
    isempty(labv) && return db.label
    foreach(_check_contextlabel, labv)

    # use primer
    found = _delfrom!(db.label, _datkey(first(labv)))
    
    # set!
    for (i, val) in enumerate(labv)
        found && i == 1 && _datval(val) === :__NOVAL && continue # ignore key only primer
        _unsafe_setlabel!(db.label, val)
    end
    
    return db.label
end

## ---------------------------------------------------------------------
function emptycontextlabel!(db::ContextDB)
    empty!(db.label.vals)
    context!(db, ["ROOT"])
    return nothing
end

function emptycontextstage!(db::ContextDB)
    empty!(db.stage)
    return nothing
end

function emptycontext!(db::ContextDB)
    emptycontextlabel!(db)
    emptycontextstage!(db)
    return nothing
end

## ---------------------------------------------------------------------
# STASH
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# CONTEXT LABEL

function stashlabel!(db::ContextDB, k::String)
    store = get!(db.extras, :CTX_LABEL_STORE) do 
        Dict{String, ContextLabel}()
    end
    store[k] = deepcopy(db.label)  # deepcopy
    return nothing
end

function unstashlabel!(db::ContextDB, k::String, del::Bool = false)
    
    store = get!(db.extras, :CTX_LABEL_STORE) do 
        Dict{String, ContextLabel}()
    end
    _label = store[k]
    empty!(db.label.vals)
    merge!(db.label.vals, _label.vals)
    del && delete!(store, k)
    return nothing
end

## ---------------------------------------------------------------------
# CONTEXT STAGE

function stashstage!(db::ContextDB, k::String)
    store = get!(db.extras, :CTX_STAGE_STORE) do 
        Dict{String, OrderedDict{String, Any}}()
    end
    store[k] = OrderedDict(db.stage)  # shadowcopy
    return nothing
end

function unstashstage!(db::ContextDB, k::String, del::Bool = false)
    store = get!(db.extras, :CTX_STAGE_STORE) do 
        Dict{String, OrderedDict{String, Any}}()
    end
    _stage = store[k]
    empty!(db.stage)
    merge!(db.stage, _stage)
    del && delete!(store, k)
    return nothing
end

## ---------------------------------------------------------------------
# FULL CONTEXT

function stashcontext!(db::ContextDB, k::String)
    stashlabel!(db, k)
    stashstage!(db, k)
    return nothing
end

function unstashcontext!(db::ContextDB, k::String, del::Bool = false)
    unstashlabel!(db, k, del)
    unstashstage!(db, k, del)
    return nothing
end

## ---------------------------------------------------------------------
## TEMP INTERFACE
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# stash -> f -> commit -> unstash
function tempcontext(f::Function, db::ContextDB, labv::Vector)
    _cache_id = string(time())
    try
        stashcontext!(db, _cache_id)
        context!(db, labv)
        return f()
    finally
        commit!(db)
        unstashcontext!(db, _cache_id, true)
    end
end

tempcontext(f::Function, db::ContextDB) = tempcontext(f, db, [])

## ---------------------------------------------------------------------
# stash -> f -> unstash
function tempcontextlabel(f::Function, db::ContextDB, labv::Vector)
    _cache_id = string(time())
    try
        stashlabel!(db, _cache_id)
        context!(db, labv)
        return f()
    finally
        unstashlabel!(db, _cache_id, true)
    end
end
tempcontextlabel(f::Function, db::ContextDB) = tempcontextlabel(f, db, [])

## ---------------------------------------------------------------------
## DATA HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# STAGE
function stage!(db::ContextDB, valv::Vector)
    for p in valv
        _check_tagdb_obj(p)
        db.stage[_datkey(p)] = _datval(p)
    end
    return nothing
end

stage!(db::ContextDB, labv::Vector, valv::Vector) = tempcontextlabel(db, labv) do
    stage!(db, valv)
end

## ---------------------------------------------------------------------
# OUTPUT

## ---------------------------------------------------------------------
# Select an object from a context

contextobj(f::Function, db::ContextDB) = get(f, db.data, hash(db.label))
contextobj(f::Function, db::ContextDB, labv::Vector) = tempcontextlabel(db, labv) do 
    return contextobj(f, db)
end

contextobj(db::ContextDB, labv::Vector) = contextobj(db, labv) do
    error("ContextLabel not found\n", db.label)
end
contextobj(db::ContextDB) = contextobj(db) do
    error("ContextLabel not found\n", db.label)
end

## ---------------------------------------------------------------------
hasobj(db::ContextDB) = haskey(db.data, hash(db.label))
hasobj(db::ContextDB, labv::Vector) = tempcontextlabel(db, labv) do 
    return hasobj(db)
end

## ---------------------------------------------------------------------
# INPUT

# commit stage data and additional vals
# It will empty! the stage
function commit!(db::ContextDB, vals::Vector)
    en = contextobj(db) do 
        db.data[hash(db.label)] = ContextObj(db.label)
    end
    commit!(en, db.stage)
    empty!(db.stage)
    commit!(en, vals)
    return en
end

commit!(db::ContextDB) = commit!(db, [])

commit!(db::ContextDB, labv::Vector, vals::Vector) = tempcontextlabel(db, labv) do
    commit!(db, vals)
end

# for commit not current context use `commit!(db, labv, [])`

## ---------------------------------------------------------------------
## FULL CONTEXT HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
function context(db::ContextDB, k::String)
    if haskey(db.label.vals, k)
        return db.label.vals[k]
    elseif haskey(db.stage, k)
        return db.stage[k]
    else
        obj = contextobj(db)
        return obj[k]
    end
end

context(db::ContextDB, labv::Vector, k::String) = tempcontextlabel(db, labv) do
    context(db, k)
end

## ---------------------------------------------------------------------
function showcontext(io::IO, db::ContextDB)
    println(io, "Context")
    
    print(io, " label      ")
    _print_kval(io, db.label.vals)
    println(io)

    # stage
    if !isempty(db.stage)
        print(io, " stage      ")
        _print_ktype(io, db.stage)
        println(io)
    end

    # obj
    obj = contextobj(db) do 
        nothing
    end
    if !isnothing(obj)
        print(io, " obj        ")
        _print_ktype(io, obj.data)
        println(io)
    end

end

showcontext(db::ContextDB) = showcontext(stdout, db)

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

function typedcontexts(io::IO, db::ContextDB)
    contexts = Set([])
    for ctx in values(db.data)
        push!(contexts, _ktype_vec(ctx.label))
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

typedcontexts(db::ContextDB) = typedcontexts(stdout, db)