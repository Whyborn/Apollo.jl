@testset "Test ice surface definition" begin
    glacier = @IceType Glacier
    fixed_ice = @IceType FixedIce

    @test glacier <: IceSurface
    @test fixed_ice <: IceSurface

    ice_mapping = Dict(glacier => 9,
                       fixed_ice => 10)
end
