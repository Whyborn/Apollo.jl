const BARREN_REQUIRED_TRAITS = Dict()

# The master barren surface type
abstract type BarrenSurface <: SurfaceClass end

"""
    @BarrenSurface name

Define a new barren surface, which acts as a functional type and subtype of BarrenSurface.
"""
macro BarrenSurface(name, barren_traits...)
    traits = read_surface_traits(BARREN_REQUIRED_TRAITS, barren_traits)

    esc(quote
        struct $(name) <: BarrenSurface end

        $name()
    end)
end

export @BarrenSurface, BarrenSurface

