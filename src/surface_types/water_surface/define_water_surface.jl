# Not sure what traits a water surface may have yet

const WATER_ALLOWED_TRAITS = Dict()

# The master water surface type
abstract type WaterSurface <: SurfaceType end

"""
    @WaterType name, traits

Define a new water surface, which acts a functional type and subtype of WaterSurface.
"""
macro WaterType(name, water_traits...)
    traits = read_surface_traits(WATER_ALLOWED_TRAITS, water_traits)

    esc(quote
        struct $(name) <: WaterSurface end

        $name()
    end)
end
export @WaterType, WaterSurface
