# Set the master surface type, which will be used in the respective tile types
"""
    SurfaceTypeDomain{N, T} <: Domain{T}

Domain for a specific surface type.
"""
struct SurfaceTypeDomain{N, T} <: Domain{T}
    tile_types::NTuple{N, DataType}
    land_ids::NTuple{N, Vector{Int}}
    fractions::NTuple{N, Vector{T}}
end

function VegetatedSurfaceDomain(surface_fractions::Array{T, 3}, mapping::Dict{Int, TileType}, domain) where {T, TileType <: SurfaceType}
    # Make sure the surface fractions are compatible with the domain
    check_land_domain(domain, surface_fractions)

    surface_types = Tuple(typeof(PFT) for (PFT, _) in mapping if  <: SurfType)

    # We want to get both the land_ids (i.e. which grid cell the tile is on, in the 1D land vector)
    # and the tile fraction in a single pass
    split_domains = Tuple(begin
        ids_and_fracs = [(to_land_index(ind, domain), frac) for (ind, frac) in enumerate(skipmissing(@view(surface_fractions[:, :, tile_id]))) if frac > 0.0]
        ids = getindex.(ids_and_fracs, 1)
        fracs = getindex.(ids_and_fracs, 2)
        ids, fracs
    end for (PFT, tile_id) in (mapping) if PFT <: SurfType)

    land_ids = getindex.(split_domains, 1)
    fracs = getindex.(split_domains, 2)

    SurfaceTypeDomain{length(surface_types), T}(surface_types, land_ids, fracs)
end
