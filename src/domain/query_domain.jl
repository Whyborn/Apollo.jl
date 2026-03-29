"""
Return the indices associated with a specified surface.
"""
function tile_indices(domain, surface)
    surface_id = findfirst(domain.tiles .== surface)
    domain.indices[surface_id]
end

"""
Return the coordinates associated with a specified surface.
"""
function tile_coords(domain, surface)
    surface_indices = tile_indices(domain, surface)
    [(domain.mask.x[i], domain.mask.y[i]) for i in surface_indices]
end
