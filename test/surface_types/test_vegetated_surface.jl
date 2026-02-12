@testset "Test vegetated surface definition" begin
    egtree = @PFT EvergreenTree phenology=evergreen
    dshrub = @PFT DeciduousShrub phenology=deciduous
    grass = @PFT Grass phenology=evergreen

    @test egtree <: VegetatedSurface
    @test dshrub <: VegetatedSurface
    @test grass <: VegetatedSurface

    @test Phenology(egtree) == Evergreen()
    @test Phenology(dshrub) == Deciduous()

    vegetated_mapping = Dict(egtree => 1,
                             dshrub => 2,
                             grass => 3)
end
