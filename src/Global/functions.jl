## ---------------------------------------------------------------------
## DB HANDLING
## ---------------------------------------------------------------------

contextdb!(db::ContextDB) = setindex!(__DB, db)
contextdb() = getindex(__DB)
function emptycontextdb!()
    empty!(__DB[].data)
    empty!(__DB[].extras)
    emptycontext!(__DB[])
    return nothing
end

emptycontextobj!() = emptycontextobj!(__DB[])
function newcontextdb!()
    db = ContextDB()
    __DB[] = db
    return db
end

function tempcontextdb(f::Function)
    _old_db = contextdb()
    try
        db = newcontextdb!()
        f()
        return db
    finally
        contextdb!(_old_db)
    end
end

## ---------------------------------------------------------------------
## CONTEXT LABEL HANDLING
## ---------------------------------------------------------------------

contextlabel() = contextlabel(__DB[])
emptycontextlabel!() = emptycontextlabel!(__DB[])
emptycontextstage!() = emptycontextstage!(__DB[])
emptycontext!() = emptycontext!(__DB[])
context!(labkv::Vector) = context!(__DB[], labkv)
typedcontexts() = typedcontexts(__DB[])

## ---------------------------------------------------------------------
# STASH
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# CONTEXT LABEL

stashlabel!(k::String) = stashlabel!(__DB[], k)
unstashlabel!(k::String, del::Bool = false) = unstashlabel!(__DB[], k, del)

bookmark!(k::Symbol) = bookmark!(__DB[], k)
bookmark(k::Symbol) = bookmark(__DB[], k)

## ---------------------------------------------------------------------
# CONTEXT STAGE

stashstage!(k::String) = stashstage!(__DB[], k)
unstashstage!(k::String, del::Bool = false) = unstashstage!(__DB[], k, del)

## ---------------------------------------------------------------------
# FULL CONTEXT

stashcontext!(k::String) = stashcontext!(__DB[], k)
unstashcontext!(k::String, del::Bool = false) = unstashcontext!(__DB[], k, del)

## ---------------------------------------------------------------------
## TEMP INTERFACE
## ---------------------------------------------------------------------

# stash -> f -> commit -> unstash
tempcontext(f::Function, labkv::Vector) = tempcontext(f, __DB[], labkv)
tempcontext(f::Function) = tempcontext(f, __DB[], [])


## ---------------------------------------------------------------------
# stash -> f -> unstash
tempcontextlabel(f::Function, labkv::Vector) = tempcontextlabel(f, __DB[], labkv)
tempcontextlabel(f::Function) = tempcontextlabel(f, __DB[], [])


## ---------------------------------------------------------------------
## DATA HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# STAGE
stage!(valv::Vector) = stage!(__DB[], valv)
isemptystage() = isemptystage(__DB[])

## ---------------------------------------------------------------------
# OUTPUT
# Select an object from a context

contextobj(f::Function) = contextobj(f, __DB[])
contextobj(f::Function, labkv::Vector) = contextobj(f, __DB[], labkv) 
contextobj(labkv::Vector) = contextobj(__DB[], labkv)
contextobj() = contextobj(__DB[])


## ---------------------------------------------------------------------
hasobj() = hasobj(__DB[])
hasobj(labkv::Vector) = hasobj(__DB[], labkv)

## ---------------------------------------------------------------------
# INPUT

# commit stage data and additional vals
# It will empty! the stage
commitcontext!(labkv::Vector) = commitcontext!(__DB[], labkv)
commitcontext!(q, qs...) = commitcontext!(__DB[], _datkvec(q, qs...))
commitcontext!() = commitcontext!(__DB[])

commit!(labkv::Vector, vals::Vector) = commit!(__DB[], labkv, vals)
commit!(vals::Vector) = commit!(__DB[], vals)
commit!(ctxv::Vector, q, qs...) = commit!(__DB[], ctxv, _datkvec(q, qs...))


## ---------------------------------------------------------------------
## FULL CONTEXT HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
context(k::String) = context(__DB[], k)
context(labkv::Vector, k::String) = context(__DB[], labkv, k)

## ---------------------------------------------------------------------
showcontext(io::IO) = showcontext(io, __DB[])
showcontext() = showcontext(__DB[])

showtypedcontexts(io::IO) = showtypedcontexts(io, __DB[])
showtypedcontexts() = showtypedcontexts(__DB[])

showbookmarks(io::IO) = showbookmarks(io, __DB[])
showbookmarks() = showbookmarks(stdout, __DB[])

## ---------------------------------------------------------------------
## QUERY HANDLING
## ---------------------------------------------------------------------

query(qv::Vector) = query(__DB[], qv)
query(q, qs...) = query(_datkvec(q, qs...))
query(f::Function, qv::Vector) = query(f, __DB[], qv)
query(f::Function, q, qs...) = query(f, __DB[], _datkvec(q, qs...))

queryall(qv::Vector) = queryall(__DB[], qv)
queryall(q, qs...) = queryall(__DB[], _datkvec(q, qs...))
