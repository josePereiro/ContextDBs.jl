using ContextDBs
using Random
using Test

@testset "ContextDBs.jl" begin

    ## ------------------------------------------------------------------
    # CacheRef
    @emptycontextdb!
    @tempcontext ["CACHE_REF"] let
    
        Random.seed!(123)
        
        cacherefs_dir!(tempdir())

        # stage ref
        _dat0 = rand(10,10)
        @stage! _ref0 = CacheRef(_dat0)
        
        # I can use ref from the db 
        # (this is just an usage example)
        _ref1 = context("_ref0")

        @test _ref0 === _ref1
        
        # this load a new copy
        _dat1 = _ref0[]
        _dat2 = _ref1[]
        
        try
            @test isfile(_ref0)
            @test isfile(_ref1)
            @test all(_dat0 .== _dat1)
            @test all(_dat1 .== _dat2)
            @test _dat0 !== _dat1
            @test _dat1 !== _dat2
        finally    
            rm(_ref0; force = true)
            rm(_ref1; force = true)
        end
    end

    ## ------------------------------------------------------------------
end
