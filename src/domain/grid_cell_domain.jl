"""
    struct GridCellDomain{T} <: Domain{T}
        x::Vector{T}
        y::Vector{T}
        mask::Matrix{Bool}
        area::Matrix{T}
    end

Define a grid cell domain.
"""
struct GridCellDomain <: Domain
    x::Vector
    y::Vector
    mask::Matrix{Bool}
    areas::Matrix
end

"""
    GridCellDomain(lons::Vector{T}, lats::Vector{T}, mask)

Create a new grid cell domain from the given mask and lon/lat coordinates.
"""
function GridCellDomain(lons::Vector{T}, lats::Vector{T}, mask)
    lons = deg2rad.(lons)
    lats = deg2rad.(lats)

    dx = lons[2] - lons[1]
    dy = lats[2] - lats[1]

    lon_bnds = [(x - dx, x + dx) for x in lons]
    lat_bnds = [(y - dy, y + dy) for y in lats]

    areas = [EARTH_RADIUS * abs(lon_bnd[2] - lon_bnd[1]) * abs(sin(lat_bnd[2]) - sin(lat_bnd[1])) for (lon_bnd, lat_bnd) in zip(lon_bnds, lat_bnds)]

    GridCellDomain(lons, lats, mask, areas)
end

count(domain::GridCellDomain) = count(domain.mask)
