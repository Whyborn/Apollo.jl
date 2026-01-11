const PFT_allowed_traits = Dict(:phenology => (:evergreen, :deciduous),
                                :leaf_type => (:needleleaf, :broadleaf)
                                )

struct Deciduous end
struct Evergreen end

macro PFT(name, args...)
    traits = Dict(trait => :placeholder for trait in PFT_allowed_traits)
    for arg in args
        if arg.head == :(=)
            if arg.args[1] in keys(PFT_allowed_traits)
                if arg.args[2] in PFT_allowed_traits[arg.args[1]]
                    traits[arg.args[1]] = arg.args[2]
                else
                    @error "$(arg.args[2]) is an unrecognised value for the $(arg.args[1]) trait."
                end
            else
                @error "$(arg.args[1]) is an unrecognised PFT trait- must be one of $(PFT_traits)"
            end
        end
    end
            
    return quote
        struct $(name) <: VegetatedTile
            name::String
        end

        if $(traits[:phenology] == :evergreen)
            phenology(PFT::$(name)) = Evergreen()
        elseif $(traits[:phenology] == :deciduous)
            phenology(PFT::$(name)) = Deciduous()
        end

        $name
    end
end
