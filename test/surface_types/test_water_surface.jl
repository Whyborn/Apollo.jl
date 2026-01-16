@testset "Test water surface definition" begin
    lake = @WaterType Lake
    river = @WaterType River

    water_mapping = Dict(lake => 7,
                         river => 8)
end
