struct VegetatedSurfaceDomain{T} <: Domain{T}
    vegetated_tiles::Tuple
end

function VegetatedSurfaceDomain(surface_fractions, mapping) end

abstract type VegetatedTile{T} end
