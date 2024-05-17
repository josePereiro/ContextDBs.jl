# # TODO: move to ProjFlows
# ## ---------------------------------------------------------------------
# ## CACHE DIR
# function cacherefs_dir!(dir::String)
#     __DB[].extras[:CACHEREFS_DIR] = dir
#     mkpath(dir)
# end

# function cacherefs_dir()
#     get!(__DB[].extras, :CACHEREFS_DIR) do 
#         cacherefs_dir!(pwd())
#     end 
# end

# ## ---------------------------------------------------------------------
# # GLOBAL 
# function CacheRef(val::Any)
#     CacheRef(cacherefs_dir(), val)
# end