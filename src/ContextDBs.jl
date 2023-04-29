# TODOs
# 1. Store context of each new file (eg. plots) so it can be queried later (eg. put a context hash on the plot name)
# 2. Version nodes. Point for git actions
# 3. Macro integration for function calls (eg. @save! now())
# 3. Macro integration for loops
# 3. Macro integration for Julia scopes (eg. @saveall # save all variables in the scope)
# 4. Implement InvertedIndices.jl stuff for querying

module ContextDBs

    using Dates
    using OrderedCollections
    
    import Base: @locals

    #! include .

    #! include Types
    include("Types/1_Context.jl")
    include("Types/2_Entry.jl")
    include("Types/3_Query.jl")
    include("Types/4_ProductQuery.jl")
    include("Types/6_ContextDB.jl")

    #! include Base
    include("Base/context.jl")
    include("Base/contextdb.jl")
    include("Base/entry.jl")
    include("Base/exportall.jl")
    include("Base/kv_interface.jl")
    include("Base/productquery.jl")
    include("Base/query.jl")
    include("Base/utils.jl")

    #! include Global
    include("Global/functions.jl")
    include("Global/globals.jl")
    include("Global/macros.jl")

    @_exportall_words()

    function __init__()
        __DB[] = ContextDB()
    end

end