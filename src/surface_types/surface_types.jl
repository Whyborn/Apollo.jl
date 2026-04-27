abstract type SurfaceClass end

"""
Read the surface traits passed, and check they form the complete set of traits required for the class.
"""
function read_surface_traits(required_traits, passed_traits)
    traits = Dict()
    for trait_spec in passed_traits
        if trait_spec.head == :(=)
            if trait_spec.args[1] in keys(required_traits)
                trait_options = required_traits[trait_spec.args[1]]
                if trait_spec.args[2] in keys(trait_options)
                    traits[trait_spec.args[1]] = trait_options[trait_spec.args[2]]
                else
                    @error "$(trait_spec.args[2]) is an unrecognised value for the $(trait_spec.args[1]) trait. Options are $(keys(trait_options))."
                end
            else
                @error "$(trait_spec.args[1]) is an unrecognised PFT trait- must be one of $(keys(required_traits))"
            end
        end
    end

    traits
end

function print_required_traits(required_traits)
    for trait, values in pairs(required_traits)
        println("\t$(String(trait)) with options:")
        for trait_values in keys(values)
            println("\t -\t$(String(trait_values))")
        end
    end
end

include("barren_surface/barren_surface.jl")
include("ice_surface/ice_surface.jl")
include("urban_surface/urban_surface.jl")
include("vegetated_surface/vegetated_surface.jl")
include("water_surface/water_surface.jl")
