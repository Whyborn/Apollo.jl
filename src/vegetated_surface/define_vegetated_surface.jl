# Define the traits that may be applied to the plant functional types
abstract type PhenologyType end

struct Deciduous <: PhenologyType end
struct Evergreen <: PhenologyType end

const PHENOLOGY_TRAITS = Dict(:deciduous => Deciduous(),
                              :evergreen => Evergreen()
                              )

# The set of allowed traits
const PFT_ALLOWED_TRAITS = Dict(:phenology => PHENOLOGY_TRAITS
                                )

# The master VegetationType
abstract type VegetatedSurface <: SurfaceType end

"""
    @PFT name, traits

Define a new PFT, which acts as a functional type and subtype of VegetationType, with
the specified traits.
"""
macro PFT(name, PFT_traits...)
    traits = read_surface_traits(PFT_ALLOWED_TRAITS, PFT_traits)

    esc(quote
        struct $(name) <: VegetatedSurface end

        Phenology(::Type{$(name)}) = $traits[:phenology]

        $name
    end)
end
