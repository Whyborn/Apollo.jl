# Not sure what traits a water surface may have yet

const WATER_REQUIRED_TRAITS = Dict()

# The master water surface type
abstract type WaterSurface <: SurfaceClass end

"""
    @WaterSurface name, traits

Define a new water surface, which acts a functional type and subtype of WaterSurface.
"""
macro WaterSurface(name, water_traits...)
    traits = read_surface_traits(WATER_REQUIRED_TRAITS, water_traits)

    esc(quote
        struct $(name) <: WaterSurface end

        $name()
    end)
end
export @WaterSurface, WaterSurface
