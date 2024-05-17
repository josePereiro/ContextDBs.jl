# # TODO: Move to ProjFlows
# import Base.getindex
# function getindex(ref::CacheRef{T})::T where {T}
#     deserialize(ref.file)    
# end

# import Base.rm
# Base.rm(ref::CacheRef; kwargs...) = rm(ref.file; kwargs...)

# import Base.isfile
# Base.isfile(ref::CacheRef) = isfile(ref.file)