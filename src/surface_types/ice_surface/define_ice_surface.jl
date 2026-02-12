# Not sure what traits a water surface may have yet

const ICE_ALLOWED_TRAITS = Dict()

# The master water surface type
abstract type IceSurface <: SurfaceType end

"""
    @IceType name, traits

Define a new ice surface, which acts a functional type and subtype of WaterSurface.
"""
macro IceType(name, ice_traits...)
    traits = read_surface_traits(ICE_ALLOWED_TRAITS, ice_traits)

    esc(quote
        struct $(name) <: IceSurface end

        $name()
    end)
end
export @IceType, IceSurface
