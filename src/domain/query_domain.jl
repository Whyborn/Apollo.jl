"""
    surface_indices(surface, domain)

Return the global indices associated with a specified surface.
"""
function surface_indices(surface, domain)
    domain_for_surface = get_surface_domain(surface, domain)
    domain_for_surface.inds
end

"""
    get_surface_domain(surface, domain)

Return the domain for the specific surface.
"""
function get_surface_domain(surface, domain)
    i = findfirst(first.(domain.tile_map) .== surface)
    domain.tile_map[i].second
end
