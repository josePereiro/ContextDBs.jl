## ---------------------------------------------------------------------
## DB HANDLING
## ---------------------------------------------------------------------

contextdb!(db::ContextDB) = setindex!(__DB, db)
contextdb() = getindex(__DB)
function emptycontextdb!() 
    empty!(__DB[].data)
    empty!(__DB[].extras)
    emptycontext!(__DB[])
end

dbcontexts(io::IO) = dbcontexts(io, __DB[])
dbcontexts() = dbcontexts(stdout)

## ---------------------------------------------------------------------
## CONTEXT HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# GETTER

context() = context(__DB[])
context(k::String) = context()[k]

## ---------------------------------------------------------------------
# SETTER

emptycontext!() = emptycontext!(__DB[])
context!(ctxv::Vector) = context!(__DB[], ctxv)
savecontext!(k::String) = savecontext!(__DB[], k)
loadcontext!(k::String, del::Bool = false) = loadcontext!(__DB[], k, del)
tempcontext(f::Function, ctxv::Vector) = tempcontext(f, __DB[], ctxv)

## ---------------------------------------------------------------------
## DATA HANDLING
## ---------------------------------------------------------------------

## ------------------------------------------------------------------
# OUTPUT
# Select an object from a context
# TODO: name alt. contextval

getval(f::Function) = getval(f, __DB[])
getval(f::Function, ctxv::Vector) = getval(f, __DB[], ctxv)
getval(ctxv::Vector) = getval(__DB[], ctxv)
getval() = getval(__DB[])

## ------------------------------------------------------------------
# INPUT

setval!(vals::Vector) = setval!(__DB[], vals)
setval!(ctxv::Vector, vals::Vector) = setval!(__DB[], ctxv, vals)
setval!(ctxv::Vector, q, qs...) = setval!(__DB[], ctxv, _datkvec(q, qs...))

## ---------------------------------------------------------------------
## QUERY HANDLING
## ---------------------------------------------------------------------

query(qv::Vector) = query(__DB[], qv)
query(q, qs...) = query(_datkvec(q, qs...))
query(f::Function, qv::Vector) = query(f, __DB[], qv)
query(f::Function, q, qs...) = query(f, __DB[], _datkvec(q, qs...))

queryall(qv::Vector) = queryall(__DB[], qv)
queryall(q, qs...) = queryall(__DB[], _datkvec(q, qs...))
