module Apollo

using CommonDataModel, NCDatasets

include("domain/domain.jl")
include("utils/utils.jl")
include("vegetated_surface/vegetated_surface.jl")
include("water_surface/water_surface.jl")
include("urban_surface/urban_surface.jl")
include("ice_surface/ice_surface.jl")

end
