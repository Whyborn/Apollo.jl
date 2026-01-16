@testset "Test urban surface definition" begin
    high_density = @UrbanType HighDensity
    residential = @UrbanType Residential
    industrial = @UrbanType Industrial

    urban_mapping = Dict(HighDensity => 4,
                         Residential => 5,
                         Industrial => 6)
                         
