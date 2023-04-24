module ContextDBs

    using Dates
    using OrderedCollections

    #! include .

    #! include Types
    include("Types/1_Context.jl")
    include("Types/2_Entry.jl")
    include("Types/5_ContextDB.jl")

    #! include Base
    include("Base/context.jl")
    include("Base/entry.jl")
    include("Base/exportall.jl")
    include("Base/global_interface.jl")
    include("Base/tagdb.jl")
    include("Base/utils.jl")

    @_exportall_words()

    function __init__()
        __DB[] = ContextDB()
        __CTX[] = Context()
    end


end