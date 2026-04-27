include("define_water_surface.jl")

function required_traits(::Type{WaterSurface})
    println("Traits required for a WaterSurface:")
    print_required_traits(WATER_REQUIRED_TRAITS)
end
