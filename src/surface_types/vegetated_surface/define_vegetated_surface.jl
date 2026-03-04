# Define the traits that may be applied to the plant functional types
abstract type PhenologyType end

struct Deciduous <: PhenologyType end
struct Evergreen <: PhenologyType end

const PHENOLOGY_TRAITS = Dict(:deciduous => Deciduous(),
                              :evergreen => Evergreen()
                              )

# The set of allowed traits
const VEGETATED_REQUIRED_TRAITS = Dict(:phenology => PHENOLOGY_TRAITS
                                )

# The master VegetationType
abstract type VegetatedSurface <: SurfaceClass end

"""
    @PFT name, traits

An alias for @VegetatedSurface.
"""
macro PFT(name, PFT_traits...)
    :(@VegetatedSurface $name $PFT_traits)
end

"""
Define a new VegetatedSurface, which acts as a functional type and subtype of VegetatedSurface, with the specified traits.
"""
macro VegetatedSurface(name, vegetated_traits...)
    traits = read_surface_traits(VEGETATED_REQUIRED_TRAITS, vegetated_traits)

    esc(quote
        struct $(name) <: VegetatedSurface end

        Phenology(::Type{$(name)}) = $traits[:phenology]

        $name()
    end)
end
export @PFT, @VegetatedSurface, VegetatedSurface
