## ----------------------------------------------------------------------------
# GLOBAL DB
## ----------------------------------------------------------------------------

contextdb!(db::ContextDB) = setindex!(__DB, db)
contextdb() = getindex(__DB)

## ---------------------------------------------------------------------
## CONTEXT HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# GETTER

context() = context(__DB[])

## ---------------------------------------------------------------------
# SETTER

emptycontext!() = emptycontext!(__DB[])
context!(ctxv::Vector) = context!(__DB[], ctxv)
savecontext!(k::String) = savecontext!(__DB[], k)
loadcontext!(k::String) = loadcontext!(__DB[], k)
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

