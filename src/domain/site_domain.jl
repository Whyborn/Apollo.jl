"""
    struct SiteDomain{T} <: Domain{T}
        x::Vector{T}
        y::Vector{T}
        flux_sites::Vector{T}
    end

Define a domain containing a number of flux sites.
"""
struct SiteDomain{T} <: Domain{T}
    x::Vector{T}
    y::Vector{T}
    flux_sites::Vector{String}
end

"""
    SiteDomain(flux_sites)

Create a new site domain from a list of site names.
"""
function SiteDomain(flux_sites)
    coords = [FLUX_SITES[name].coord for name in flux_sites]

    x = getindex.(coords, 1)
    y = getindex.(coords, 2)

    SiteDomain(x, y, flux_sites)
end

"""
    nvalues(domain::SiteDomain)

Return the number of sites in the domain.
"""
count(domain::SiteDomain) = length(domain.flux_sites)
