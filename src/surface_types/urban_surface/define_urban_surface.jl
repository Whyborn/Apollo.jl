# Not sure what traits an urban surface may have

const URBAN_REQUIRED_TRAITS = Dict()

# The master urban surface type
abstract type UrbanSurface <: SurfaceClass end

"""
    @UrbanSurface name, traits

Define a new Urban surface, which acts a functional type and subtype of WaterSurface.
"""
macro UrbanSurface(name, urban_traits...)
    traits = read_surface_traits(URBAN_REQUIRED_TRAITS, urban_traits)

    esc(quote
        struct $(name) <: UrbanSurface end

        $name()
    end)
end
export @UrbanSurface, UrbanSurface
