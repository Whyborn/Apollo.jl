abstract type Domain{T} end

"""
Domain{T, N, M}

Data structure describing the computational domain for the simulation.

$(FIELDS)
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
Construct a Domain using vectors of longitudes and latitudes, a land_area_fraction array and a surface class mapping. The shape of the longitudes by latitudes should match the trailing dimensions of the land_area_fraction array. This signature is used for gridded domains.

If the lon_bnds and lat_bnds are not supplied, then they are inferred from the passed latitudes and longitudes. If `normalise` is true, the sum of fractions in a grid cell is normalised to 1.
"""
function Domain(lons, lats, land_area_fraction{T, 3}, mapping; lon_bnds=nothing, lat_bnds=nothing, mask=nothing, normalise=false) where {T}

    # First validate the land area fraction. This includes checking the mapping is workable
    # with the passed land fractions i.e. the user hasn't denoted a tile index greater than
    # the number of slices in the array
    @assert (size(land_area_fraction, 2), size(land_area_fraction, 3)) == (length(lons), length(lats)), "The size of the land_area_fraction and the supplied longitudes and latitudes are not compatible. Size of land_area_fraction: $(size(land_area_fraction)), with lons: $(length(lons)) and lats: $(length(lats))"

    # Convert the mapping values to vectors for consistent handling and array accessing,
    # then validate
    mapping = Dict(surface => inds isa Vector ? inds : [inds] for (surface, inds) in mapping)
    validate_surface_mapping(land_area_fraction, mapping)

    # Were the bounds supplied?
    if (isnothing(lon_bnds))
        lon_bnds = infer_grid_bounds(lons)
    end

    if (isnothing(lat_bnds))
        lat_bnds = infer_grid_bounds(lats)
    end

    # Now we have handled everything that is specific to the gridded domains- reshape the
    # data so that it can be treated in the same way as site runs.
    # This means that the land_area_fraction should represent spatial points in a single
    # dimension, and the mask should be a vector (if supplied)
    land_area_fractions = reshape(land_area_fractions, (size(land_area_fractions), :))
    mask = isnothing(mask) ? mask : vec(mask)

    # Vectorize the dimensions
    lons = repeat(lons, inner=length(lats), outer=1)
    lats = repeat(lats, inner=1, outer=length(lons))
    lon_bnds = repeat(lon_bnds, inner=(1, length(lats)), outer=(1, 1))
    lat_bnds = repeat(lat_bnds, inner=(1, 1), outer=(1, length(lons)))

    # Call the generic function used for both domain types
    Domain(lons, lats, land_area_fractions, mapping; lon_bnds=lon_bnds, lat_bnds=lat_bnds, mask=mask, normalise=normalise)

end

"""
Construct a Domain using vectors of x and y coordinates (typically latitude and longitude), a land_area_fraction array and a surface class mapping. The longitudes and latitudes are paired, representing specific locations. This signature is used for site domains, and for processing of gridded domains after some preprocessing.

If the lon_bnds and lat_bnds are not supplied, then it is assumed that the coordinates represent longitudes and latitudes, and the size of the grid cells is assumed to be 0.01 degrees.
"""

function Domain(lons, lats, land_area_fraction{T 2}, mapping; lon_bnds=nothing, lat_bnds=nothing, mask=nothing, normalise=false) where {T}

    # Create the lons and lats bounds if not supplied
    if isnothing(lon_bnds)
        lon_bnds = infer_site_bounds(lons)
    end

    if isnothing(lat_bnds)
        lat_bnds = infer_site_bounds(lats)
    end
    # Verify that the bounds are valid if supplied
    #
    # Now we start processing the land fractions- we want to work with 2 copies of the
    # underlying land_area_fractions. One which is the full array of data, that we can
    # index using the values in the mapping, and one which is a view of only the slices
    # included in the mapping.
    # All the indices included in the mapping
    all_inds = [ind for indices in values(mapping) for ind in indices]
    active_fractions = @view(land_area_fractions[all_inds, :])

    # Set the mask
    if (isnothing(mask))
        # Not supplied- created the mask. Take all of the "pages" of the land area array
        # that are mapped to a surface class, and check which locations have a non-zero
        # total surface fraction (and not missing which may represent ocean)
        frac_sum = dropdims(sum(active_fractions, dims=1), dims=1)
        mask = @. !ismissing(frac_sum) && frac_sum > 0.0
    else
        # Ensure that the mask size is compatible
        @assert size(mask) == size(land_area_fraction, 2)
    end

    # Optionally normalise the fractions
    if normalise
        # Note that this modifies in place, in the variable that is a view into the
        # original array
        active_fractions .= active_fractions ./ sum(active_fractions, dims=1)
    end

    # Now create the vectors for the respective surface classes
    tiles, indices, fractions = process_land_area_fractions_and_mapping(land_area_fraction, mapping, mask)

end

"""
Ensure that the specified mapping is valid with the given land area fractions. The only condition is that the mapping doesn't contain any indices outside the range available in the land area fractions i.e. 1 <= indx <= size(land_area_fraction, 1)
"""
function validate_surface_mapping(land_area_fraction, mapping)
    min_indx = 1
    max_indx = size(land_area_fraction, 1)
    check_failed = false
    for (surface, inds) in mapping
        for ind in inds
            if !(min_indx <= ind <= max_indx)
                @warn "Index $ind for surface class $surface falls outside the allowed range of 1 to size(land_area_fraction, 1), which is $max_indx"
                check_failed = true
            end
        end
    end

    @assert !check_failed, "Supplied mapping is invalid for the given land area fractions" 
end

"""
Infer the cell bounds for gridded domains, based on the list of cell centre locations passed.
"""
function infer_grid_bounds(points::Vector{T}) where {T}
    # To infer the bounds, assume that the coordinates are ascending
    @assert issorted(points), "Supplied points are not monotonically ascending"
    
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
        bounds[1, i] = points[1] - 0.5 * lower
        bounds[2, i] = points[1] + 0.5 * upper
    end

    bounds
end

"""
Infer the cell bounds for site domains, based on the list of cell centre locations passed.
"""
function infer_grid_bounds(points::Vector{T}) where {T}
    
    bounds = Matrix{T}(undef, 2, length(points))
    bounds[1, :] = points .- 0.01
    bounds[2, :] = points .+ 0.01

    bounds
end

"""
Validate that the bounds are appropriate for the specified longitudes
"""
function check_bounds_valid(points, point_bnds)
    @assert all(@view(point_bnds[1, :]) .< points .< @view(point_bnds[2, :])), "Some bounds are do not bracket their associated point."
end

"""
Process the given land area fractions and the mapping to create the `tile`, `indices` and `fractions` components of the `Domain` derived type.
"""
function process_land_area_fractions_and_mapping(land_area_fraction::Matrix{T}, mapping, mask::Vector) where {T}


    tiles = (); indices = (); fractions = ()

    for (surface_class, mapped_indices) in mapping
        class_fractions = dropdims(sum(@view(land_area_fraction[mapped_indices]
    components = Tuple(begin
                           # We need to track the index in terms of land points
                            land_counter=1
                            for (ind, m) in enumerate(mask)
                            if m

                                

    for (surface_class, mapped_indices) in mapping
        tiles = (tiles..., surface_class)

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

function check_land_domain(domain::Domain, data::Array{T, 3}) where {T}
    for i = 1:size(data, 3)
        @assert all(domain.mask .== .!(ismissing.(@view(data[:, :, i])))), "Supplied data is expected to be on the same grid as the land mask, but it is not."
    end
end

function check_land_domain(domain::Domain, data::Array{T, 4}) where {T}
    for i = 1:size(data, 3), j = 1:size(data, 4)
        @assert all(domain.mask .== .!(ismissing.(@view(data[:, :, i, j])))), "Supplied data is expected to be on the same grid as the land mask, but it is not."
    end
end
