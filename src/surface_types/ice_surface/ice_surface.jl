include("define_ice_surface.jl")

function required_traits(::Type{IceSurface})
    println("Traits required for an IceSurface:")
    print_required_traits(ICE_REQUIRED_TRAITS)
end
