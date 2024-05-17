using ContextDBs
using Random
using Test

@testset "ContextDBs.jl" begin

    ## ------------------------------------------------------------------
    # @tempcontext
    let
        let
            @newcontextdb!
            @test length(contextdb()) == 0
    
            _val0 = rand(10,10)
            @tempcontext ["subcontext"] begin
                @test @isdefined _val0
                @stage! _val1 = _val0
            end
            @test @isdefined _val1
            @test length(contextdb()) == 1
            _val2 = query(["ROOT"])["_val1"]
            @test _val1 === _val0
            @test _val2 === _val0
        end
        # Test it is contained by outer scope
        @test !@isdefined _val1
    end

    # ## ------------------------------------------------------------------
    # # CacheRef
    # # TODO: move to ProjFlows
    # let
    #     @newcontextdb!
    #     @tempcontext ["CACHE_REF"] let
        
    #         Random.seed!(123)
            
    #         cacherefs_dir!(tempdir())

    #         # stage ref
    #         _dat0 = rand(10,10)
    #         @stage! _ref0 = CacheRef(_dat0)
            
    #         # I can use ref from the db 
    #         # (this is just an usage example)
    #         _ref1 = context("_ref0")

    #         @test _ref0 === _ref1
            
    #         # this load a new copy
    #         _dat1 = _ref0[]
    #         _dat2 = _ref1[]
            
    #         try
    #             @test isfile(_ref0)
    #             @test isfile(_ref1)
    #             @test all(_dat0 .== _dat1)
    #             @test all(_dat1 .== _dat2)
    #             @test _dat0 !== _dat1
    #             @test _dat1 !== _dat2
    #         finally    
    #             rm(_ref0; force = true)
    #             rm(_ref1; force = true)
    #         end
    #     end
    # end

    ## ------------------------------------------------------------------
    @newcontextdb!
    @tempcontext ["TEST"] let
        for it1 in 1:2
            @context! it1
            for it2 in 1:2
                @context! it2
                @stage! var3 = (it1, it2)
                @commitcontext!
            end
        end
    end

    let
        # queries
        qry = queryall("ROOT", "TEST", "it1")
        @test length(qry) == 4
        qry = queryall("ROOT", "TEST", "it2")
        @test length(qry) == 4

        # label hashing
        # order does not matter
        l1 = ContextLabel(["ROOT", "SIMVER" => v"0.1.0", "TEST", "it1" => 1, "it2" => 1])
        l2 = ContextLabel(["ROOT", "SIMVER" => v"0.1.0", "TEST", "it2" => 1, "it1" => 1])
        @test hash(l1) == hash(l2)
        @show hash(l1)
        @show hash(l2)

        # different values
        l1 = ContextLabel(["ROOT", "SIMVER" => v"0.1.0", "TEST", "it1" => 2, "it2" => 1])
        l2 = ContextLabel(["ROOT", "SIMVER" => v"0.1.0", "TEST", "it1" => 1, "it2" => 2])
        @test hash(l1) != hash(l2)
        @show hash(l1)
        @show hash(l2)
    end
end
