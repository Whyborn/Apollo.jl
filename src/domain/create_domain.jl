abstract type Domain{T} end

"""
Domain{T, N, M}

Data structure describing the computational domain for the simulation.

"""
struct Domain{T, N, M}
    # The mask describing where the points are located on the grid.
    mask::Array{Bool, M}
    # List of cell centre longitudes
    lons::Vector
    # List of cell centre latitudes 
    lats::Vector
    # Matrix of cell longitude bounds
    lon_bnds::Matrix
    # Matrix of cell latitude bounds
    lat_bnds::Matrix
    # Tuple of surface classes used in the simulation
    tiles::NTuple{N, SurfaceClass}
    # Tuple of vectors, listing the cells containing the corresponding surface class
    indices::NTuple{N, Vector{Int}}
    # Tuple of vectors, describing the fractions of the given cell covered by the surface class
    fractions::NTuple{N, Vector{T}}
end

"""
Construct a Domain using vectors of longitudes and latitudes, a vegetation_area_fraction array and a surface class mapping. The shape of the longitudes by latitudes should match the trailing dimensions of the vegetation_area_fraction array. This signature is used for gridded domains.

If the lon_bnds and lat_bnds are not supplied, then they are inferred from the passed latitudes and longitudes. If `normalise` is true, the sum of fractions in a grid cell is normalised to 1.
"""
function Domain(lons, lats, vegetation_area_fraction::Array{T, 3}, mapping; lon_bnds=nothing, lat_bnds=nothing, mask=nothing, normalise=false) where {T}

    # First validate the land area fraction. This includes checking the mapping is workable
    # with the passed land fractions i.e. the user hasn't denoted a tile index greater than
    # the number of slices in the array
    @assert size(vegetation_area_fraction, 1) == length(lons) && size(vegetation_area_fraction, 2) == length(lats) "The size of the vegetation_area_fraction and the supplied longitudes and latitudes are not compatible. Size of vegetation_area_fraction: $(size(vegetation_area_fraction)), with lons: $(length(lons)) and lats: $(length(lats))"

    # Convert the mapping values to vectors for consistent handling and array accessing,
    # then validate
    mapping = Dict(surface => inds isa Vector ? inds : [inds] for (surface, inds) in mapping)
    validate_surface_mapping(vegetation_area_fraction, mapping)

    # Were the bounds supplied?
    if (isnothing(lon_bnds))
        lon_bnds = infer_grid_bounds(lons)
    end
    check_bounds_valid(lons, lon_bnds)

    if (isnothing(lat_bnds))
        lat_bnds = infer_grid_bounds(lats)
    end
    check_bounds_valid(lats, lat_bnds)

    # When creating the mask, we only want to work with the indices representing active surface
    # types. So cut out a view of those indices from the complete land area fractions
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

    # Optionally normalise the fractions
    if normalise
        # Note that this modifies in place, in the variable that is a view into the
        # original array
        active_area_fraction .= active_area_fraction ./ sum(active_fractions, dims=2)
    end

    # Use the mask and land fractions to yield the index/fraction vectors
    tiles, indices, fractions = process_vegetation_area_fractions(vegetation_area_fraction, mapping, mask)
    
    # Vectorize the dimensions
    lons = repeat(lons, inner=length(lats), outer=1)
    lats = repeat(lats, inner=1, outer=length(lons))
    lon_bnds = repeat(lon_bnds, inner=(1, length(lats)), outer=(1, 1))
    lat_bnds = repeat(lat_bnds, inner=(1, 1), outer=(1, length(lons)))

    # Call the generic function used for both domain types
    Domain{eltype(vegetation_area_fraction), length(tiles), 2}(mask, lons, lats, lon_bnds, lat_bnds, tiles, indices, fractions)

end

"""
Construct a Domain using vectors of x and y coordinates (typically latitude and longitude), a vegetation_area_fraction array and a surface class mapping. The longitudes and latitudes are paired, representing specific locations. This signature is used for site domains, and for processing of gridded domains after some preprocessing.

If the lon_bnds and lat_bnds are not supplied, then it is assumed that the coordinates represent longitudes and latitudes, and the size of the grid cells is assumed to be 0.01 degrees.
"""

function Domain(lons, lats, vegetation_area_fraction::Matrix{T}, mapping; lon_bnds=nothing, lat_bnds=nothing, mask=nothing, normalise=false) where {T}

    # Check that the lons and lats are valid
    @assert length(lons) == length(lats) == size(vegetation_area_fraction, 2) "The longitudes, latitudes and number of columns in the vegetation_area_fraction array must be the same."

    # Create the lons and lats bounds if not supplied
    if isnothing(lon_bnds)
        lon_bnds = infer_site_bounds(lons)
    end

    if isnothing(lat_bnds)
        lat_bnds = infer_site_bounds(lats)
    end

    # Validate that the bounds are valid
    check_bounds_valid(lons, lon_bnds)
    check_bounds_valid(lats, lat_bnds)

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

    # Optionally normalise the fractions
    if normalise
        # Note that this modifies in place, in the variable that is a view into the
        # original array
        active_fractions .= active_area_fraction ./ sum(active_area_fraction, dims=2)
    end

    # Now create the vectors for the respective surface classes
    tiles, indices, fractions = process_vegetation_area_fractions_and_mapping(vegetation_area_fraction, mapping, vec(mask))

    # Call the generic function used for both domain types
    Domain{eltype(vegetation_area_fraction), length(tiles), 1}(mask, lons, lats, lon_bnds, lat_bnds, tiles, indices, fractions)

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
Process the given land area fractions and the mapping to create the `tile`, `indices` and `fractions` components of the `Domain` derived type.
"""
function process_vegetation_area_fractions(vegetation_area_fraction, mapping, mask)

    # First ensure that the land area fraction and mask are vectorized
    vegetation_area_fraction = reshape(vegetation_area_fraction, (:, size(vegetation_area_fraction, 1)))
    mask = vec(mask)

    tiles = (); indices = (); fractions = ()

    for (surface_class, mapped_indices) in mapping
        # Summate over the indices assigned to the surface class, then iterate through the non-zero and non-masked fractions
        class_total = dropdims(sum(@view(vegetation_area_fraction[mapped_indices, :]), dims=2), dims=2)
        indices_fracs = [(i, frac) for (i, (m, frac)) in enumerate(zip(mask, class_total)) if (m && frac > 0.0)]

        tiles = (tiles..., surface_class)
        indices = (indices..., getindex.(indices_fracs, 1))
        fractions = (fractions..., getindex.(indices_fracs, 2))
    end

    tiles, indices, fractions
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
