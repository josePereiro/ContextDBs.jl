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
getindex(db::ContextDB, i, k::String) = getindex(db, :, k)[i]

# extract commands
getindex(db::ContextDB, f::Function, k::String) = f(getindex(db, :, k))

## ---------------------------------------------------------------------
## CONTEXT LABEL HANDLING
## ---------------------------------------------------------------------

contextlabel(db::ContextDB) = db.label

## ---------------------------------------------------------------------
# SETTER

function context!(db::ContextDB, lkvec::Vector)
    
    # some checks
    isempty(lkvec) && return nothing
    
    # resolve primer
    primer, lkvec = _resolve_primer(db, lkvec)
    
    # check contextlabel
    foreach(_check_contextlabel, lkvec)
    _check_unique_keys(lkvec)
    
    # set!
    empty!(db.label.vals)
    for kv in lkvec
        _unsafe_setlabel!(db.label, kv)
    end
    
    return nothing
end

# function context!(db::ContextDB, labv::Vector)
    
#     # some checks
#     isempty(labv) && return db.label
#     foreach(_check_contextlabel, labv)

#     # use primer
#     found = _delfrom!(db.label, _datkey(first(labv)))
    
#     # set!
#     for (i, val) in enumerate(labv)
#         found && i == 1 && _datval(val) === :__NOVAL && continue # ignore key only primer
#         _unsafe_setlabel!(db.label, val)
#     end
    
#     return db.label
# end

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

function emptycontextobj!(db::ContextDB)
    obj = contextobj(db) do 
        nothing    
    end
    isnothing(obj) && return nothing
    
    delete!(db.data, labelhash(obj))

    return nothing
end

## ---------------------------------------------------------------------
# CHECKPOINTS
## ---------------------------------------------------------------------
function bookmark!(db::ContextDB, k::Symbol)
    store = get!(db.extras, :CTX_LABEL_CHECKPOINT) do 
        Dict{Symbol, ContextLabel}()
    end
    store[k] = deepcopy(db.label)  # deepcopy
    return nothing
end

function bookmark(db::ContextDB, k::Symbol)
    store = get!(db.extras, :CTX_LABEL_CHECKPOINT) do 
        Dict{Symbol, ContextLabel}()
    end
    return get(store, k) do
        error("Bookmark missing, key ", k)
    end
end

function showbookmarks(io::IO, db::ContextDB)
    store = get!(db.extras, :CTX_LABEL_CHECKPOINT) do 
        Dict{String, ContextLabel}()
    end

    println(io, " Bookmarks: ")
    for (k, label) in store
        # println(io, k, " => ", _print_kval(io, label.vals))
        println(io, repr(k), " => ", repr(label))
    end
end
showbookmarks(db::ContextDB) = showbookmarks(stdout, db)

## ---------------------------------------------------------------------
# STASH
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# CONTEXT LABEL

function stashlabel!(db::ContextDB, k::String)
    store = get!(db.extras, :CTX_LABEL_STASH) do 
        Dict{String, ContextLabel}()
    end
    store[k] = deepcopy(db.label)  # deepcopy
    return nothing
end

function unstashlabel!(db::ContextDB, k::String, del::Bool = false)
    store = get!(db.extras, :CTX_LABEL_STASH) do 
        Dict{String, ContextLabel}()
    end
    _label = get(store, k) do
        error("Stash missing, key ", k)
    end
    empty!(db.label.vals)
    merge!(db.label.vals, _label.vals)
    del && delete!(store, k)
    return nothing
end

## ---------------------------------------------------------------------
# CONTEXT STAGE

function stashstage!(db::ContextDB, k::String)
    store = get!(db.extras, :CTX_STAGE_STASH) do 
        Dict{String, OrderedDict{String, Any}}()
    end
    store[k] = OrderedDict(db.stage)  # shadowcopy
    return nothing
end

function unstashstage!(db::ContextDB, k::String, del::Bool = false)
    store = get!(db.extras, :CTX_STAGE_STASH) do 
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
function tempcontext(f::Function, db::ContextDB, labkv::Vector)
    _cache_id = string(time())
    try
        stashcontext!(db, _cache_id)
        context!(db, labkv)
        return f()
    finally
        isempty(db.stage) || commitcontext!(db)
        unstashcontext!(db, _cache_id, true)
    end
end

tempcontext(f::Function, db::ContextDB) = tempcontext(f, db, [])

## ---------------------------------------------------------------------
# stash -> f -> unstash
function tempcontextlabel(f::Function, db::ContextDB, labkv::Vector)
    _cache_id = string(time())
    try
        stashlabel!(db, _cache_id)
        context!(db, labkv)
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
        # TODO: Think about allowing overwriting or not
        # It might be usefull for preventing missing commit cmds
        db.stage[_datkey(p)] = _datval(p)
    end
    return nothing
end

## ---------------------------------------------------------------------
# OUTPUT

## ---------------------------------------------------------------------
# Select an object from a context

contextobj(f::Function, db::ContextDB) = get(f, db.data, labelhash(db))
contextobj(f::Function, db::ContextDB, labkv::Vector) = tempcontextlabel(db, labkv) do 
    return contextobj(f, db)
end

contextobj(db::ContextDB, labkv::Vector) = contextobj(db, labkv) do
    error("ContextLabel not found\n", db.label)
end
contextobj(db::ContextDB) = contextobj(db) do
    error("ContextLabel not found\n", db.label)
end

## ---------------------------------------------------------------------
hasobj(db::ContextDB) = haskey(db.data, labelhash(db))
hasobj(db::ContextDB, labkv::Vector) = tempcontextlabel(db, labkv) do 
    return hasobj(db)
end

## ---------------------------------------------------------------------
# INPUT

# commit stage data and additional vals
# It will empty! the stage

function commitcontext!(db::ContextDB)
    isemptystage(db) && error("Nothing to commit!")
    en = contextobj(db) do 
        db.data[labelhash(db)] = ContextObj(db.label)
    end
    commit!(en, db.stage)
    empty!(db.stage)
    return en
end

commitcontext!(db::ContextDB, labkv::Vector) = tempcontextlabel(db, labkv) do
    commitcontext!(db)
end

function commit!(db::ContextDB, vals::Vector)
    stage!(db, vals)
    commitcontext!(db)
end

commit!(db::ContextDB, labkv::Vector, vals::Vector) = tempcontextlabel(db, labkv) do
    commit!(db, vals)
end

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

context(db::ContextDB, labkv::Vector, k::String) = tempcontextlabel(db, labkv) do
    context(db, k)
end

## ---------------------------------------------------------------------
function showcontext(io::IO, db::ContextDB)
    println(io, "Current Context:")
    
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

## ------------------------------------------------------------------
## QUERYING
## ------------------------------------------------------------------

# ------------------------------------------------------------------
function query(f::Function, db::ContextDB, qkvec::Vector)
    # integrate context
    found = nothing
    
    # qkvec = _build_qkvec(db.label, qkvec)
    
    primer, qkvec = _resolve_primer(db, qkvec)
    isnothing(primer) && error("You must set a primer. qkvec ", qkvec)

    pq = ProductQuery(qkvec)
    for q in pq.qs # for each query
        for (h, obj) in db.data # for each obj
            if _obj_match(obj, q) 
                isnothing(found) || error("The query do not solve an unique entry. See 'queryall'")
                found = obj
            end
        end
    end
    return isnothing(found) ? f() : found
end
query(f::Function, db::ContextDB, q, qs...) = query(f, db, _datkvec(q, qs...))

query(db::ContextDB, qkvec::Vector) = query(db, qkvec) do 
    error("The query do not solve any entry")
end
query(db::ContextDB, q, qs...) = query(db, _datkvec(q, qs...))

# ------------------------------------------------------------------
function queryall(db::ContextDB, qkvec::Vector)
    isempty(db.data) && return db
    found = OrderedDict{UInt, ContextObj}()

    # qkvec = _build_qkvec(db.label, qkvec)

    primer, qkvec = _resolve_primer(db, qkvec)
    isnothing(primer) && error("You must set a primer. qkvec ", qkvec)

    pq = ProductQuery(qkvec)
    # TODO: make more efficient
    for q in pq.qs # for each query
        for (h, obj) in db.data # for each obj
            if _obj_match(obj, q)
                setindex!(found, obj, h)
            end
        end
    end
    isempty(found) && error("The query/context do not match any entry.")
    return ContextDB(db, found)
end
queryall(db::ContextDB, q, qs...) = queryall(db, _datkvec(q, qs...))

## ---------------------------------------------------------------------
## UTILS
## ---------------------------------------------------------------------

# resolve the lkvec for context labeling handling
function _resolve_primer(db::ContextDB, lkvec0::Vector)
    
    primer = nothing
    lkvec = Any[]

    # resolve bookmark primer
    if isa(first(lkvec0), Symbol)
        primer = first(lkvec0)
        label0 = bookmark(db, primer)
        lkvec = _datkvec(label0.vals)
        for (i, kv) in enumerate(lkvec0)
            i == 1 && continue
            push!(lkvec, kv)
        end
    end

    # resolve context primer
    if isnothing(primer)
        primer0 = _datkey(first(lkvec0)) # possible primer
        label0 = _datkvec(db.label.vals)

        for kv in label0
            push!(lkvec, kv)
            if primer0 == _datkey(kv)
                # primer found
                primer = primer0
                break
            end
        end

        for (i, kv) in enumerate(lkvec0)
            if isnothing(primer)
                # No primer, just push
                push!(lkvec, kv)
            elseif i == 1 
                # If primer has an explicit value overwrite
                if _datval(kv) !== :__NOVAL && !isempty(lkvec)
                    lkvec[end] = kv
                end
            else
                # push the rest
                push!(lkvec, kv)
            end
        end
    end
    
    # compact
    _compact_kvec!(lkvec)

    return primer, lkvec
end

import Base.isempty
isempty(db::ContextDB) = isempty(db.data)
isemptystage(db::ContextDB) = isempty(db.stage)

import Base.lastindex
lastindex(db::ContextDB) = lastindex(db.data.vals)

import Base.firstindex
firstindex(db::ContextDB) = firstindex(db.data.vals)

import Base.length
length(db::ContextDB) = length(db.data.vals)

import Base.collect
collect(db::ContextDB) = collect(db.data.vals)

function contextlabelkeys(db::ContextDB)
    # collect
    contexts = Set{String}()
    for ctx in values(db.data)
        push!(contexts, keys(ctx.label)...)
    end
    return collect(contexts)
end

function contextdatakeys(db::ContextDB)
    # collect
    contexts = Set{String}()
    for ctx in values(db.data)
        push!(contexts, keys(ctx.data)...)
    end
    return collect(contexts)
end

contextobjkeys(db::ContextDB) = union(contextlabelkeys(db), contextdatakeys(db))

function typedcontexts(db::ContextDB)
    # collect
    contexts = Set([])
    for ctx in values(db.data)
        push!(contexts, _ktype_vec(ctx.label))
    end
    return collect(contexts)
end

function showtypedcontexts(io::IO, db::ContextDB)
    
    # collect
    contexts = typedcontexts(db)
    sort!(contexts; by = length)

    # print
    println(io, "DB Typed Contexts:")
    for vals in contexts
        print(io, " [")
        for p in vals
            k, val = _datkey(p), _datval(p)
            if val === :__NOVAL; print(io, repr(k), ", ")
                else; print(io, repr(k), " => ::", repr(val), ", ")
            end
        end
        println(io, "]")
    end
end

showtypedcontexts(db::ContextDB) = showtypedcontexts(stdout, db)

import Base.show
function show(io::IO, db::ContextDB)
    println(io, "ContextDB with ", length(db.data), " contextualized objects")
    showcontext(io, db)
    showtypedcontexts(io, db)
end

labelhash(db::ContextDB) = hash(contextlabel(db))

