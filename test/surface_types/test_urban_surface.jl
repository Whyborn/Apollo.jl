@testset "Test urban surface definition" begin
    high_density = @UrbanType HighDensity
    residential = @UrbanType Residential
    industrial = @UrbanType Industrial

    @test high_density <: UrbanSurface
    @test residential <: UrbanSurface
    @test industrial <: UrbanSurface

    urban_mapping = Dict(HighDensity => 4,
                         Residential => 5,
                         Industrial => 6)
end
