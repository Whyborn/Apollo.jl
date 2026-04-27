include("define_vegetated_surface.jl")

function required_traits(::Type{VegetatedSurface})
    println("Required traits for a VegetatedSurface:")
    print_required_traits(VEGETATED_REQUIRED_TRAITS)
end
