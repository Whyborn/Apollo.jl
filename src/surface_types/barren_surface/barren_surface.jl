include("define_barren_surface.jl")

function required_traits(::Type{BarrenSurface})
    println("Traits required for a BarrenSurface:")
    print_required_traits(BARREN_REQUIRED_TYPES)
end
