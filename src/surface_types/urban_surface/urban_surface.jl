include("define_urban_surface.jl")

function required_traits(::Type{UrbanSurface})
    println("Traits required for an UrbanSurface:")
    print_required_traits(URBAN_REQUIRED_TRAITS)
end
