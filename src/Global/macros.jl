## ---------------------------------------------------------------------
## CONTEXT HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
function __emptycontext_expr()
    return quote
        ContextDB.emptycontext!()
    end
end

macro emptycontext!() 
    __emptycontext_expr()
end

## ---------------------------------------------------------------------
function __context_expr(exs...)
    # unpack
    exv = _unpack_exprs(exs...)
    # resolve kvec
    _expr = _collect_and_eval_kvec_expr(exv)
    # exec context!
    _expr = quote
        $(_expr)
        ContextDBs.context!(_kvec)
    end
    return _expr
end

macro context!(exs...)
    __context_expr(exs...)
end


## ---------------------------------------------------------------------
function __savecontext_expr(ex)
    return quote
        ContextDBs.savecontext!($(esc(ex)))
    end
end

macro savecontext!(ex)
    __savecontext_expr(ex)
end

## ---------------------------------------------------------------------
function __loadcontext_expr(ex)
    return quote
        ContextDBs.loadcontext!($(esc(ex)))
    end
end

macro loadcontext!(ex)
    __loadcontext_expr(ex)
end

## ---------------------------------------------------------------------
function __tempcontext_expr(ctx_ex, block_ex)
    
    # check/unpack input
    ctx_exv = _unpack_vec_expr_err(ctx_ex)
    block_ex = _block_expr_err(block_ex)

    # resolve ctx kvec
    _expr = _collect_and_eval_kvec_expr(ctx_exv)

    # do temp stuff
    _expr = quote
        $(_expr)
        try
            ContextDBs.savecontext!("__WITHCONTEXT_CACHE__")
            ContextDBs.context!(_kvec)
            # exec block
            $(esc(block_ex))
        finally
            ContextDBs.loadcontext!("__WITHCONTEXT_CACHE__")
        end
    end
    return _expr
end

macro tempcontext(ctx_ex, block_ex)
    __tempcontext_expr(ctx_ex, block_ex)
end

## ---------------------------------------------------------------------
## DATA HANDLING
## ---------------------------------------------------------------------

## ------------------------------------------------------------------
# INPUT

function __setval_expr(val_exs...)
    
    ctx_exv, val_exv = _unpack_first_vec_expr(val_exs...)

    # resolve ctx kvec
    _ctxv_expr = _collect_and_eval_kvec_expr(ctx_exv)
    _valv_expr = _collect_and_eval_kvec_expr(val_exv)

    # setval
    return quote
        $(_ctxv_expr)
        local _ctxv = _kvec
        $(_valv_expr)
        local _valv = _kvec
        ContextDBs.setval!(_ctxv, _valv)
    end
end

macro setval!(val_exs...)
    __setval_expr(val_exs...)
end

# setval!(vals::Vector) = setval!(__DB[], vals)
# setval!(ctxv::Vector, vals::Vector) = setval!(__DB[], ctxv, vals)


## ----------------------------------------------------------------------------
## MACROS UTILS
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
# return the expr if it is a block
function _block_expr(ex::Expr)
    ex.head == :block && return ex
    ex.head == :let && return ex
    return nothing
end
_block_expr(ex) = nothing

function _block_expr_err(ex)
    ex = _block_expr(ex)
    isnothing(ex) && error("A begin/let block is expected")
    return ex
end

## ----------------------------------------------------------------------------
# uncat :([a b]) into a vector of Exprs [:a, :b]
function _unpack_vec_expr(ex::Expr)
    ex.head == :vect && return ex.args
    ex.head == :vcat && return ex.args
    ex.head == :hcat && return ex.args
    # ex.head == :tuple && return ex.args
    # ex.head == :braces && return ex.args
    return nothing
end
_unpack_vec_expr(ex) = nothing

function _unpack_vec_expr_err(exs...)
    exs = _unpack_vec_expr(exs...)
    isnothing(exs) && error("Expected a vector expr. eg. [a, b = 1] ")
    return exs
end

## ----------------------------------------------------------------------------
# general unpacking, return a vector of exprs
function _unpack_exprs(ex)
    exs = _unpack_vec_expr(ex)
    return isnothing(exs) ? [ex] : exs
end
_unpack_exprs(exs...) = collect(exs)

## ----------------------------------------------------------------------------
# From an 'atomic' expression extract the key
_expr_key(ex::Symbol) = string(ex)
_expr_key(ex::String) = ex
_expr_key(ex) = nothing
function _expr_key(ex::Expr)
    if ex.head === :call && ex.args[1] === :(=>)
        # a => expr
        return string(ex.args[2])
    elseif ex.head === :(=)
        # a = expr
        return string(ex.args[1])
    elseif ex.head == :global && ex.args[1].head === :(=) 
        # global a = expr
        return string(ex.args[1].args[1])
    elseif ex.head == :local && ex.args[1].head === :(=) 
        # local a = expr
        return string(ex.args[1].args[1])
    else
        return nothing
    end
end

function _expr_key_err(ex)
    _key = _expr_key(ex)
    isnothing(_key) && error("The expression is too complex ;(")
    return _key
end

## ---------------------------------------------------------------------
# An expression that given a Vectro of Exprs fill a local _kvec vector
# while evaluating (esc) the exprs
function _collect_and_eval_kvec_expr(exv::Vector)
    # init _kvec
    _full = quote
        local _kvec = []
    end
    # fill/exec _kvec
    for ex in exv
        _key = _expr_key_err(ex)
        _full = quote
            $(_full)
            local _key = $(_key)
            local _exec = $(esc(ex))
            local _val = ContextDBs._datval(_exec)
            push!(_kvec, _key => _val)
        end
    end
    return _full
end

## ---------------------------------------------------------------------
# unpack a set of expression into a vec head (if exist) and a tail 
function _unpack_first_vec_expr(exs...)
    head_exv, tail_exv = [], []
    for (i, ex) in enumerate(exs)
        if i == 1
            exv = _unpack_vec_expr(ex)
            if !isnothing(exv)
                head_exv = exv
                continue
            end
        end
        push!(tail_exv, ex)
    end
    return head_exv, tail_exv
end