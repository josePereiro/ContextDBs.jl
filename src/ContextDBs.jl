# IDEAS
# 1. Store context of each new file (eg. plots) so it can be queried later (eg. put a context hash on the plot name)
# 2. Version nodes. Point for git actions
# 3. Macro integration for function calls (eg. @save! now())
# 3. Macro integration for loops
# 3. Macro integration for Julia scopes (eg. @saveall # save all variables in the scope)
# 4. Implement InvertedIndices.jl stuff for querying

# ------------------------------------------------------------------
# IDEAS
# I want a combination of some level of herarchy and horinzontality into the contexts
# vcontext (vertical) and an hcontext (horizontal)
# c1 (vertical)
# |
# c2, c3, c4 (horizontal)
# |
# c5 (vertical)

# IDEAS
# Implement an staging interface for accomulating data
# The context interface is fine, but some times data appears in the scripts before 
# the contexts is completed, so, the 'save' operation need to be postponded

# IDEAS
# Have an interface for accessing 'contextual' data. Just as context("exp_time"), 
# but not only in the context itself, I want to also access staged/commited data.

# IDEAS
# Add an autoreport folder to ProjFlow dir tree.
# There, all plots, annotations, context will be collected into an automatic document.

# IDEAS
# Have a recent interface so I can access the last commited context with a given label.
# This is good for fast chaining workflow stages.

# IDEAS
# Nested contexts: A set of data related from a context subset must be access from a superset.
# Ex: Given ["Bla"] => [A = 1], A must be accessible from ["Blo", "Bla"]

module ContextDBs

    using Dates
    using OrderedCollections
    using Serialization
    
    import Base: @locals

    #! include .

    #! include Types
    include("Types/1_ContextLabel.jl")
    include("Types/2_ContextObj.jl")
    include("Types/3_ProductQuery.jl")
    include("Types/4_ContextDB.jl")
    include("Types/5_CacheRef.jl")

    #! include Base
    include("Base/cacheref.jl")
    include("Base/contextdb.jl")
    include("Base/contextlabel.jl")
    include("Base/contextobj.jl")
    include("Base/exportall.jl")
    include("Base/kv_interface.jl")
    include("Base/productquery.jl")
    include("Base/utils.jl")

    #! include Global
    include("Global/cacheref.jl")
    include("Global/functions.jl")
    include("Global/globals.jl")
    include("Global/macros.jl")

    @_exportall_words()

    function __init__()
        __DB[] = ContextDB()
    end

end