# ----------------------------------------------------------------------------
# GLOBALS
# ----------------------------------------------------------------------------
const __DB = Ref{ContextDB}()
const __CTX = Ref{Context}()

# ----------------------------------------------------------------------------
# MACROS
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# INPUT

function __save_expr(exs...)
    exs = _unpack_exprs(exs...)
    _full = :()
    for ex in exs
        _key = _expr_key_err(ex)
        _full = quote
            $(_full)
            local _key = $(_key)
            local _exec = $(esc(ex))
            local _val = ContextDBs._datval(_exec)
            set!($(esc(ContextDBs.__DB[])), $(esc(ContextDBs.__CTX[])), _key => _val)
            _exec # return
        end
    end
    return _full
end

# Set value to the global DB based on the current Context
macro save!(exs...)
    __save_expr(exs...)
end

# ----------------------------------------------------------------------------
function __pushcontext_exrp(exs...)
    exs = _unpack_exprs(exs...)
    _full = :()
    for ex in exs
        _key = _expr_key_err(ex)
        _full = quote
            $(_full)
            local _key = $(_key)
            local _exec = $(esc(ex))
            local _val = ContextDBs._datval(_exec)
            push!($(esc(ContextDBs.__CTX[])), _key => _val)
            _exec # return
        end
    end
    return _full
end
__pushcontext_exrp() = nothing

# Protects from overwriting
macro pushcontext!(ex, exs...)
    __pushcontext_exrp(ex, exs...)
end

# pushcontext(val, vals...) = push!(ContextDBs.__CTX[], val, vals...)

# ----------------------------------------------------------------------------
function __upcontext_exrp(exs...)
    exs = _unpack_exprs(exs...)
    _full = :()
    for ex in exs
        _key = _expr_key_err(ex)
        _full = quote
            $(_full)
            local _key = $(_key)
            local _exec = $(esc(ex))
            local _val = ContextDBs._datval(_exec)
            set!($(esc(ContextDBs.__CTX[])), _key => _val)
            _exec # return
        end
    end
    return _full
end
__upcontext_exrp() = nothing

macro upcontext!(ex, exs...)
    __upcontext_exrp(ex, exs...)
end

macro context!(ex, exs...)
    __upcontext_exrp(ex, exs...)
end

# upcontext(val, vals...) = push!(ContextDBs.__CTX[], val, vals...)

# ----------------------------------------------------------------------------
# function withcontext(f::Function, c)
#     context(val, vals...)
#     f()
#     clearcontext!(val, :)
# end

function __withcontext_expr(val_ex, block_ex)

    val_exs = _exprs_in_vec_err(val_ex)
    if !(isa(block_ex, Expr) && (block_ex.head == :block || block_ex.head == :let))
        error("A begin/let block is expected")
    end

    push_expr = isempty(val_exs) ? nothing : __pushcontext_exrp(val_exs...)
    clear_expr = isempty(val_exs) ? nothing : __clearcontext_expr(first(val_exs))
    return quote
        $(push_expr)
        $(esc(block_ex))
        $(clear_expr)
    end
end

macro withcontext(val_ex, block_ex)
    __withcontext_expr(val_ex, block_ex)
end

# ----------------------------------------------------------------------------
# BOOM

macro emptyDB!()
    empty!(ContextDBs.__DB[])
end

macro initcontext!(ex...)
    empty!(ContextDBs.__CTX[])
    __pushcontext_exrp(ex...)
end

# ----------------------------------------------------------------------------
# TODO: Implement all clearcontext! interface
function __clearcontext_expr(ex)
    ex = _unpack_exprs(ex)[1]
    _key = _expr_key_err(ex)
    quote
        local _key = $(_key)
        local _exec = $(esc(ex))
        ContextDBs.clearcontext!($(esc(ContextDBs.__CTX[])), _key, :)
    end
end

macro clearcontext!(ex)
    __clearcontext_expr(ex)
end

# ----------------------------------------------------------------------------
# TODO: add handling of for loops
# @withcontext for i in enumerate(1:10)
#     i+1
# end

# ----------------------------------------------------------------------------
# OUTPUT
# TODO: find better names

getentry() = get(__DB[], __CTX[])

macro getentry()
    :(ContextDBs.getentry())
end

setDB!(db::ContextDB) = (__DB[] = db; db)
getDB() = __DB[]

macro getDB()
    :(ContextDBs.getDB())
end

# ----------------------------------------------------------------------------
# MACROS UTILS
# ----------------------------------------------------------------------------
_expr_key(ex::Symbol) = string(ex)
_expr_key(ex::String) = ex
_expr_key(ex) = nothing
function _expr_key(ex::Expr)
    if ex.head === :call && ex.args[1] === :(=>)
        # a => val
        return string(ex.args[2])
    elseif ex.head === :(=)
        # a = val
        return string(ex.args[1])
    elseif ex.head == :global && ex.args[1].head === :(=) 
        # global a = val
        return string(ex.args[1].args[1])
    elseif ex.head == :local && ex.args[1].head === :(=) 
        # local a = val
        return string(ex.args[1].args[1])
    else
        return nothing
    end
end

function _expr_key_err(ex)
    _key = _expr_key(ex)
    isnothing(_key) && error("The expecting is to complex ;(")
    return _key
end

function _exprs_args_block(exs...)
    block_ex = nothing
    val_exs = []
    for ex in exs
        if isa(ex, Expr) && (ex.head == :block || ex.head == :let)
            block_ex = ex
            break
            else; push!(val_exs, ex)
        end
    end
    return val_exs, block_ex
end

function _exprs_args_block_err(exs...)
    val_exs, block_ex = _exprs_args_block(exs...)
    isnothing(block_ex) && error("A begin/let block is expected")
    return val_exs, block_ex
end

# uncat :([a b]) into a vector of Exprs [:a, :b]
function _exprs_in_vec(ex::Expr)
    ex.head == :vect && return ex.args
    ex.head == :vcat && return ex.args
    ex.head == :hcat && return ex.args
    # ex.head == :tuple && return ex.args
    # ex.head == :braces && return ex.args
    return nothing
end
_exprs_in_vec(ex) = nothing

function _exprs_in_vec_err(exs...)
    exs = _exprs_in_vec(exs...)
    isnothing(exs) && error("Expected a vector syntax. eg. @withcontext [a, b = 1] begin...")
    return exs
end

function _unpack_exprs(ex)
    exs = _exprs_in_vec(ex)
    return isnothing(exs) ? [ex] : exs
end
_unpack_exprs(exs...) = collect(exs)