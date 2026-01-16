@testset "Test ice surface definition" begin
    glacier = @IceType Glacier
    fixed_ice = @IceType FixedIce

    ice_mapping = Dict(glacier => 9,
                       fixed_ice => 10)
end
