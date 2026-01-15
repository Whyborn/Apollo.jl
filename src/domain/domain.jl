abstract type Domain{T} end

function define_on_domain(vars::NTuple{N, Symbol}, domain::Domain{T}, dims=()) where {T}
    nvalues = count(domain)

    arr = zeros(T, (nvalues, dims...))

    # A named tuple of var => arr pairs, used to construct the ComponentVector
    t = NamedTuple{vars}(arr)

    ComponentVector(t)
end

function check_land_domain(domain::Domain, data::Array{T, 3}) where {T}
    for i = 1:size(data, 3)
        @assert all(domain.mask .== !.(ismissing.(@view(data[:, :, i])))), "Supplied data is expected to be on the same grid as the land mask, but it is not."
    end
end

function check_land_domain(domain::Domain, data::Array{T, 4}) where {T}
    for i = 1:size(data, 3), j = 1:size(data, 4)
        @assert all(domain.mask .== !.(ismissing.(@view(data[:, :, i, j])))), "Supplied data is expected to be on the same grid as the land mask, but it is not."
    end
end

include("grid_cell_domain.jl")
include("surface_type_domain.jl")
