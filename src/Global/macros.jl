## ---------------------------------------------------------------------
## DB HANDLING
## ---------------------------------------------------------------------

function __emptycontextdb_expr()
    return quote
        ContextDBs.emptycontextdb!()
    end
end

macro emptycontextdb!()
    __emptycontextdb_expr()
end

function __emptycontextobj_expr()
    return quote
        ContextDBs.emptycontextobj!()
    end
end

macro emptycontextobj!()
    __emptycontextobj_expr()
end

function __newcontextdb_expr()
    return quote
        ContextDBs.newcontextdb!()
    end
end

macro newcontextdb!()
    __newcontextdb_expr()
end

function __tempcontextdb_expr(block_ex)
    return quote
        local _old_db = ContextDBs.contextdb()
        try
            local _new_db = ContextDBs.newcontextdb!()
            # exec block
            $(esc(block_ex))
        finally
            ContextDBs.contextdb!(_old_db)
        end
    end
end

macro tempcontextdb(ex)
    block_ex = _block_expr_err(ex)
    __tempcontextdb_expr(block_ex)
end

## ---------------------------------------------------------------------
## CONTEXT HANDLING
## ---------------------------------------------------------------------

function __contextlabel_expr()
    return quote
        ContextDBs.contextlabel()
    end
end

macro contextlabel()
    __contextlabel_expr()
end

function __emptycontextlabel_expr()
    return quote
        ContextDBs.emptycontextlabel!()
    end
end

macro emptycontextlabel!()
    __emptycontextlabel_expr()
end

function __emptycontextstage_expr()
    return quote
        ContextDBs.emptycontextstage!()
    end
end

macro emptycontextstage!()
    __emptycontextstage_expr()
end

function __emptycontext_expr()
    return quote
        ContextDBs.emptycontext!()
    end
end

macro emptycontext!()
    __emptycontext_expr()
end

## ---------------------------------------------------------------------

function __showcontext_expr()
    return quote
        ContextDBs.showcontext()
    end
end

macro showcontext()
    __showcontext_expr()
end

function __typedcontexts_expr()
    return quote
        ContextDBs.showtypedcontexts()
    end
end

macro showtypedcontexts()
    __typedcontexts_expr()
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
# STASH
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# CONTEXT LABEL

function __stashlabel_expr(ex)
    return quote
        ContextDBs.stashlabel!($(esc(ex)))
    end
end

macro stashlabel!(ex::String)
    __stashlabel_expr(ex)
end

function __unstashlabel_expr(ex)
    return quote
        ContextDBs.unstashlabel!($(esc(ex)))
    end
end

macro unstashlabel!(ex::String)
    __unstashlabel_expr(ex)
end

## ---------------------------------------------------------------------
# BOOKMARKS

function __bookmark_expr(ex::QuoteNode)
    return quote
        ContextDBs.bookmark!($(esc(ex)))
    end
end
__bookmark_expr(::Any) = error("Expected a symbol literal")

macro bookmark!(ex)
    __bookmark_expr(ex)
end

## ---------------------------------------------------------------------
# CONTEXT STAGE

function __stashstage_expr(ex)
    return quote
        ContextDBs.stashstage!($(esc(ex)))
    end
end

macro stashstage!(ex::String)
    __stashstage_expr(ex)
end

function __unstashstage_expr(ex)
    return quote
        ContextDBs.unstashstage!($(esc(ex)))
    end
end

macro unstashstage!(ex::String)
    __unstashstage_expr(ex)
end

## ---------------------------------------------------------------------
# FULL CONTEXT

function __stashcontext_expr(ex)
    return quote
        ContextDBs.stashcontext!($(esc(ex)))
    end
end

macro stashcontext!(ex::String)
    __stashcontext_expr(ex)
end

function __unstashcontext_expr(ex)
    return quote
        ContextDBs.unstashcontext!($(esc(ex)))
    end
end

macro unstashcontext!(ex::String)
    __unstashcontext_expr(ex)
end

## ---------------------------------------------------------------------
## TEMP INTERFACE
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# stash -> f -> commit -> unstash
function __tempcontext_expr(ctx_ex, block_ex)
    
    # check/unpack input
    ctx_exv = _unpack_vec_expr_err(ctx_ex)
    block_ex = _block_expr_err(block_ex)

    # resolve ctx kvec
    _expr = _collect_and_eval_kvec_expr(ctx_exv)

    # do temp stuff
    _expr = quote
        $(_expr)
        local _cache_id = string(time())
        try
            ContextDBs.stashcontext!(_cache_id)
            ContextDBs.context!(_kvec)
            # exec block
            $(esc(block_ex))
        finally
            ContextDBs.isemptystage() || ContextDBs.commitcontext!()
            ContextDBs.unstashcontext!(_cache_id, true)
        end
    end
    return _expr
end

macro tempcontext(ctx_ex, block_ex)
    __tempcontext_expr(ctx_ex, block_ex)
end

## ---------------------------------------------------------------------
# stash -> f -> unstash
function __tempcontextlabel_expr(ctx_ex, block_ex)
    
    # check/unpack input
    ctx_exv = _unpack_vec_expr_err(ctx_ex)
    block_ex = _block_expr_err(block_ex)

    # resolve ctx kvec
    _expr = _collect_and_eval_kvec_expr(ctx_exv)

    # do temp stuff
    _expr = quote
        $(_expr)
        local _cache_id = string(time())
        try
            ContextDBs.stashlabel!(_cache_id)
            ContextDBs.context!(_kvec)
            # exec block
            $(esc(block_ex))
        finally
            ContextDBs.unstashlabel!(_cache_id, true)
        end
    end
    return _expr
end

macro tempcontextlabel(ctx_ex, block_ex)
    __tempcontextlabel_expr(ctx_ex, block_ex)
end

## ---------------------------------------------------------------------
## DATA HANDLING
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
# INPUT

## ---------------------------------------------------------------------
# STAGE

function __stage_expr(val_exs...)
    
    # unpack
    exv = _unpack_exprs(val_exs...)
    # resolve kvec
    _expr = _collect_and_eval_kvec_expr(exv)
    # exec context!
    _expr = quote
        $(_expr)
        ContextDBs.stage!(_kvec)
    end
    return _expr
    
end

macro stage!(val_exs...)
    __stage_expr(val_exs...)
end

## ---------------------------------------------------------------------
# COMMIT

function __commitcontext_expr()
    return quote
        ContextDBs.commitcontext!()
    end
end

macro commitcontext!()
    __commitcontext_expr()
end

function __commitcontext_expr(ex)
    
    ctx_exv = _unpack_vec_expr_err(ex)

    # resolve ctx kvec
    _ctxv_expr = _collect_and_eval_kvec_expr(ctx_exv)

    # setval
    return quote
        $(_ctxv_expr)
        local _ctxv = _kvec
        ContextDBs.commitcontext!(_ctxv)
    end
end

macro commitcontext!(ex)
    __commitcontext_expr(ex)
end

function __commit_expr(val_exs...)
    
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
        ContextDBs.commit!(_ctxv, _valv)
    end
end

macro commit!(val_exs...)
    __commit_expr(val_exs...)
end


## ---------------------------------------------------------------------
## MACROS UTILS
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
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

## ---------------------------------------------------------------------
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

## ---------------------------------------------------------------------
# general unpacking, return a vector of exprs
function _unpack_exprs(ex)
    exs = _unpack_vec_expr(ex)
    return isnothing(exs) ? [ex] : exs
end
_unpack_exprs(exs...) = collect(exs)

## ---------------------------------------------------------------------
# From an 'atomic' expression extract the key and a value parser
_parse_kv_expr(ex::Symbol) = (string(ex), identity)
_parse_kv_expr(ex::String) = (ex, (x) -> :__NOVAL)
# _parse_kv_expr(ex::QuoteNode) = (ex.value, (x) -> nothing)
_parse_kv_expr(::Any) = (nothing, nothing)
function _parse_kv_expr(ex::Expr)
    _key = nothing
    _val_parser = nothing # extract val from the exec value
    if ex.head === :call && ex.args[1] === :(=>)
        # a => expr
        _key = string(ex.args[2])
        _val_parser = last
    elseif ex.head === :(=)
        # a = expr
        _key = string(ex.args[1])
        _val_parser = identity
    elseif ex.head == :global && ex.args[1].head === :(=) 
        # global a = expr
        _key = string(ex.args[1].args[1])
        _val_parser = identity
    elseif ex.head == :local && ex.args[1].head === :(=) 
        # local a = expr
        _key = string(ex.args[1].args[1])
        _val_parser = identity
    end

    return (_key, _val_parser)
end

function _parse_kv_expr_err(ex)
    _key, _val_parser = _parse_kv_expr(ex)
    isnothing(_key) && error("The expression is too complex ;(")
    return _key, _val_parser
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
        _key, _val_parser = _parse_kv_expr_err(ex)
        _full = quote
            $(_full)
            local _key = $(_key)#::String
            local _exec = $(esc(ex))
            local _val = $(_val_parser)(_exec)
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