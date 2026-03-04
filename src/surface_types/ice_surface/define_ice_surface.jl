# Not sure what traits a water surface may have yet

const ICE_REQUIRED_TRAITS = Dict()

# The master ice surface type
abstract type IceSurface <: SurfaceClass end

"""
    @IceType name, traits

Define a new ice surface, which acts a functional type and subtype of WaterSurface.
"""
macro IceSurface(name, ice_traits...)
    traits = read_surface_traits(ICE_REQUIRED_TRAITS, ice_traits)

    esc(quote
        struct $(name) <: IceSurface end

        $name()
    end)
end
export @IceSurface, IceSurface
