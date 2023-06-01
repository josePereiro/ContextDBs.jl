# TODO: move out, probably to ProjFlows
struct CacheRef{T}
    file::String
    function CacheRef(cache_dir, val::T) where {T}
        file = joinpath(cache_dir, string(hash(val), ".cacheref.jls"))
        serialize(file, val)
        return new{T}(file)
    end
end
