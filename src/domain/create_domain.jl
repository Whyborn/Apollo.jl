abstract type DomainMap end

"""
    GriddedMap{T} <: DomainMap

A mapping defined on a regular grid. `x` and `y` are the grid axes (vectors of
cell-centre coordinates), so the mask has shape `(length(x), length(y))`.
`x_bnds` and `y_bnds` are `(2, n)` matrices holding the lower and upper
bounds of each cell along the respective axis.
"""
struct GriddedMap{T} <: DomainMap{T}
    mask::Matrix{Bool}
    x::Vector{T}
    y::Vector{T}
    x_bnds::Matrix{T}
    y_bnds::Matrix{T}
end

"""
    SiteMap{T} <: DomainMap

A mapping defined over an unordered collection of point locations. `x` and `y`
are paired vectors of the same length `n`, each entry describing one site.
`mask` is a length-`n` boolean vector. `x_bnds` and `y_bnds` are
`(2, n)` matrices holding the lower and upper bounds associated with each site.
"""
struct SiteMap{T} <: DomainMap{T}
    mask::Vector{Bool}
    x::Vector{T}
    y::Vector{T}
    x_bnds::Matrix{T}
    y_bnds::Matrix{T}
end

"""
    TileMap{T, N}

Defines the surface type mapping onto the simulation domain.
"""
struct TileMap{T}
    indices::Vector{Int}
    fractions::Vector{T}
end

"""
Domain{T, N}

Data structure describing the computational domain for the simulation.

"""
struct Domain{T, N}
    # The map which describes the mapping from tile vectors back to the original domain.
    sim_map::DomainMap{T}
    # Tuple of surface classes used in the simulation
    tile_map::NTuple{N, Pair{SurfaceClass, TileMap{T}}}
end

"""
Construct a Domain using vectors of longitudes and latitudes, a vegetation_area_fraction array and a surface class mapping. The shape of the longitudes by latitudes should match the trailing dimensions of the vegetation_area_fraction array. This signature is used for gridded domains.

If the x_bnds and y_bnds are not supplied, then they are inferred from the passed latitudes and longitudes. If `normalise` is true, the sum of fractions in a grid cell is normalised to 1.
"""
function Domain(x, y, vegetation_area_fraction::Array{T, 3}, mapping; x_bnds=nothing, y_bnds=nothing, mask=nothing, normalise=false) where {T}

    # First validate the land area fraction. This includes checking the mapping is workable
    # with the passed land fractions i.e. the user hasn't denoted a tile index greater than
    # the number of slices in the array
    check_domain_compatible(selectdim(vegetation_area_fraction, ndims(vegetation_area_fraction), 1), x, y) "The size of the vegetation_area_fraction and the supplied longitudes and latitudes are not compatible."

    # Convert the mapping values to vectors for consistent handling and array accessing,
    # then validate
    mapping = Dict(surface => inds isa Vector ? inds : [inds] for (surface, inds) in mapping)
    validate_surface_mapping(vegetation_area_fraction, mapping)

    # Were the bounds supplied?
    if (isnothing(x_bnds))
        x_bnds = infer_grid_bounds(x)
    else
        check_bounds_valid(x, x_bnds)
    end

    if (isnothing(y_bnds))
        y_bnds = infer_grid_bounds(y)
    else
        check_bounds_valid(y, y_bnds)
    end

    # Create the mask based on just the active surfaces
    active_inds = [ind for indices in values(mapping) for ind in indices]
    active_area_fraction = @view(vegetation_area_fraction[:, :, active_inds])

    # Now use this view to create the mask
    if isnothing(mask)
        # Note that non-land points may be treated as missing
        frac_sums = dropdims(sum(active_area_fraction, dims=3), dims=3)
        mask = @. !ismissing(frac_sums) && frac_sums > 0.0
    else
        @assert size(mask) == (size(vegetation_area_fraction, 1), size(vegetation_area_fraction, 2)), "Supplied mask does not match the shape of the land area fractions."
    end

    sim_map = GriddedMap{T}(mask, x, y, x_bnds, y_bnds)

    # Optionally normalise the fractions
    if normalise
        # Note that this modifies in place, in the variable that is a view into the
        # original array
        active_area_fraction .= active_area_fraction ./ sum(active_fractions, dims=3)
    end

    # Now iterate through each of the surfaces and create the tile map
    tile_map = Tuple(begin
                    fracs_for_surface = dropdims(sum(vegetation_area_fraction[:, :, pages], dims=3), dims=3)
                    mask_for_surface = @. !ismissing(fracs_for_surface) && fracs_for_surface > 0.0
                    surface_inds = [ind for (ind, m) in enumerate(mask_for_surface) if m]
                    fracs = fracs_for_surface[surface_inds]
                    surface => TileMap(surface_inds, fracs)
                end for (surface, pages) in pairs(mapping)
               )

    Domain{T, length(tile_map)}(sim_map, tile_map)
end

"""
Construct a Domain using vectors of x and y coordinates (typically latitude and longitude), a vegetation_area_fraction array and a surface class mapping. The longitudes and latitudes are paired, representing specific locations. This signature is used for site domains, and for processing of gridded domains after some preprocessing.

If the x_bnds and y_bnds are not supplied, then it is assumed that the coordinates represent longitudes and latitudes, and the size of the grid cells is assumed to be 0.01 degrees.
"""

function Domain(x, y, vegetation_area_fraction::Matrix{T}, mapping; x_bnds=nothing, y_bnds=nothing, mask=nothing, normalise=false) where {T}

    # Check that the x and y are valid
    @assert length(x) == length(y) == size(vegetation_area_fraction, 2) "The longitudes, latitudes and number of columns in the vegetation_area_fraction array must be the same."

    # Create the x and y bounds if not supplied
    if isnothing(x_bnds)
        x_bnds = infer_site_bounds(x)
    end

    if isnothing(y_bnds)
        y_bnds = infer_site_bounds(y)
    end

    # Validate that the bounds are valid
    check_bounds_valid(x, x_bnds)
    check_bounds_valid(y, y_bnds)

    # Now we start processing the land fractions- we want to work with 2 copies of the
    # underlying vegetation_area_fractions. One which is the full array of data, that we can
    # index using the values in the mapping, and one which is a view of only the slices
    # included in the mapping.
    all_inds = [ind for indices in values(mapping) for ind in indices]
    active_area_fraction = @view(vegetation_area_fractions[:, all_inds])

    # Set the mask
    if (isnothing(mask))
        # Not supplied- created the mask. Take all of the "pages" of the land area array
        # that are mapped to a surface class, and check which locations have a non-zero
        # total surface fraction (and not missing which may represent ocean)
        frac_sum = dropdims(sum(active_area_fraction, dims=2), dims=2)
        mask = @. !ismissing(frac_sum) && frac_sum > 0.0
    else
        # Ensure that the mask size is compatible
        @assert length(mask) == size(vegetation_area_fraction, 1) "Supplied mask does not match the size of the vegetation_area_fraction."
    end

    sim_map = SiteMap(mask, x, y, x_bnds, y_bnds)

    # Optionally normalise the fractions
    if normalise
        # Note that this modifies in place, in the variable that is a view into the
        # original array
        active_fractions .= active_area_fraction ./ sum(active_area_fraction, dims=2)
    end

    # Now iterate through each of the surfaces and create the tile map
    tile_map = Tuple(begin
                    fracs_for_surface = dropdims(sum(vegetation_area_fraction[:, :, pages], dims=2), dims=2)
                    mask_for_surface = @. !ismissing(fracs_for_surface) && fracs_for_surface > 0.0
                    surface_inds = [ind for (ind, m) in enumerate(mask_for_surface) if m]
                    fracs = fracs_for_surface[surface_inds]
                    surface => TileMap(surface_inds, fracs)
                end for (surface, pages) in pairs(mapping)
               )

    Domain{T, length(tile_map)}(sim_map, tile_map)
end

"""
Check that the given array is compatible with the given dimensions.
"""
function check_domain_compatible(arr, dimensions...)
    @assert ndims(arr) == length(dimensions) "Rank of array is not the same as number of dimensions passed."
    for i = 1:length(dimensions)
        @assert size(arr, i) == dimensions[i] "Length of dimension $i is expected to be $(dimensions[i]), but is $(size(arr, i))."
    end
end
"""
Ensure that the specified mapping is valid with the given land area fractions. The only condition is that the mapping doesn't contain any indices outside the range available in the land area fractions i.e. 1 <= indx <= size(vegetation_area_fraction, 1)
"""
function validate_surface_mapping(vegetation_area_fraction, mapping)
    min_indx = 1
    max_indx = size(vegetation_area_fraction, 1)
    check_failed = false
    for (surface, inds) in mapping
        for ind in inds
            if !(min_indx <= ind <= max_indx)
                @warn "Index $ind for surface class $surface falls outside the allowed range of 1 to size(vegetation_area_fraction, 1), which is $max_indx"
                check_failed = true
            end
        end
    end

    @assert !check_failed "Supplied mapping is invalid for the given land area fractions" 
end

"""
Infer the cell bounds for gridded domains, based on the list of cell centre locations passed.
"""
function infer_grid_bounds(points::Vector{T}) where {T}
    # To infer the bounds, assume that the coordinates are ascending
    @assert issorted(points) "Supplied points are not monotonically ascending"
    
    bounds = Matrix{T}(undef, 2, length(points))
    for i = 1:length(points)
        if i == 1
            lower = points[2] - points[1]
            upper = lower
        elseif i == length(points)
            lower = points[end] - points[end-1]
            upper = lower
        else
            lower = points[i] - points[i-1]
            upper = points[i+1] - points[i]
        end
        bounds[1, i] = points[i] - 0.5 * lower
        bounds[2, i] = points[i] + 0.5 * upper
    end

    bounds
end

"""
Infer the cell bounds for site domains, based on the list of cell centre locations passed.
"""
function infer_site_bounds(points::Vector{T}) where {T}
    
    bounds = Matrix{T}(undef, 2, length(points))
    bounds[1, :] = points .- 0.01
    bounds[2, :] = points .+ 0.01

    bounds
end

"""
Validate that the bounds are appropriate for the specified longitudes
"""
function check_bounds_valid(points, point_bnds)
    @assert all(@view(point_bnds[1, :]) .< points .< @view(point_bnds[2, :])) "Some bounds are do not bracket their associated point."
end

"""
    define_on_domain(vars, domain::Domain{T}, dims=()

Define the set of variables denoted by the names in `vars` on the specified domain, with the optional trailing dimensions provided by dims.
"""
function define_on_domain(vars, domain::Domain{T}, dims=()) where {T}
    nvalues = count(domain)

    # Define arrays of the desired size
    arr = zeros(T, (nvalues, dims...))

    # A named tuple of var => arr pairs, used to construct the ComponentVector
    t = NamedTuple{vars}(arr)

    # Create entries to add to the variable library
    which_domain = Dict(var => typeof(domain) for var in vars)

    which_domain, ComponentVector(t)
end
