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

## ---------------------------------------------------------------------
## CONTEXT LABEL HANDLING
## ---------------------------------------------------------------------

contextlabel() = contextlabel(__DB[])
emptycontextlabel!() = emptycontextlabel!(__DB[])
emptycontextstage!() = emptycontextstage!(__DB[])
emptycontext!() = emptycontext!(__DB[])
context!(labv::Vector) = context!(__DB[], labv)

## ---------------------------------------------------------------------
# STASH
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# CONTEXT LABEL

stashlabel!(k::String) = stashlabel!(__DB[], k)
unstashlabel!(k::String, del::Bool = false) = unstashlabel!(__DB[], k, del)

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
tempcontext(f::Function, labv::Vector) = tempcontext(f, __DB[], labv)
tempcontext(f::Function) = tempcontext(f, __DB[], [])


## ---------------------------------------------------------------------
# stash -> f -> unstash
tempcontextlabel(f::Function, labv::Vector) = tempcontextlabel(f, __DB[], labv)
tempcontextlabel(f::Function) = tempcontextlabel(f, __DB[], [])


## ---------------------------------------------------------------------
## DATA HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# STAGE
stage!(valv::Vector) = stage!(__DB[], valv)
stage!(labv::Vector, valv::Vector) = stage!(__DB[], labv, valv)

## ---------------------------------------------------------------------
# OUTPUT
# Select an object from a context

contextobj(f::Function) = contextobj(f, __DB[])
contextobj(f::Function, labv::Vector) = contextobj(f, __DB[], labv) 
contextobj(labv::Vector) = contextobj(__DB[], labv)
contextobj() = contextobj(__DB[])


## ---------------------------------------------------------------------
hasobj() = hasobj(__DB[])
hasobj(labv::Vector) = hasobj(__DB[], labv)

## ---------------------------------------------------------------------
# INPUT

# commit stage data and additional vals
# It will empty! the stage
commit!(labv::Vector, vals::Vector) = commit!(__DB[], labv, vals)
commit!(vals::Vector) = commit!(__DB[], vals)
commit!(ctxv::Vector, q, qs...) = commit!(__DB[], ctxv, _datkvec(q, qs...))
commit!() = commit!(__DB[])

## ---------------------------------------------------------------------
## FULL CONTEXT HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
context(k::String) = context(__DB[], k)
context(labv::Vector, k::String) = context(__DB[], labv, k)

## ---------------------------------------------------------------------
showcontext(io::IO) = showcontext(io, __DB[])
showcontext() = showcontext(__DB[])

typedcontexts(io::IO) = typedcontexts(io, __DB[])
typedcontexts() = typedcontexts(__DB[])

## ---------------------------------------------------------------------
## QUERY HANDLING
## ---------------------------------------------------------------------

query(qv::Vector) = query(__DB[], qv)
query(q, qs...) = query(_datkvec(q, qs...))
query(f::Function, qv::Vector) = query(f, __DB[], qv)
query(f::Function, q, qs...) = query(f, __DB[], _datkvec(q, qs...))

queryall(qv::Vector) = queryall(__DB[], qv)
queryall(q, qs...) = queryall(__DB[], _datkvec(q, qs...))
