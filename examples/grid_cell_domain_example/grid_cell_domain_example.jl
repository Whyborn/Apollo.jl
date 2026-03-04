using Apollo

include("surface_definition.jl")

ex_size = (17, 9, 17)

fracs = rand(Float64, ex_size)
lons = collect(LinRange(50, 51, ex_size[1]))
lats = collect(LinRange(10, 11, ex_size[2]))
