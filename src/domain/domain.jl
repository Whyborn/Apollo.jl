abstract type Domain{T} end

function define_on_domain(vars::NTuple{N, Symbol}, domain::Domain{T}) where {T}
    nvalues = count(domain)

    arr = zeros(T, nvalues)

    # A named tuple of var => arr pairs, used to construct the ComponentVector
    t = NamedTuple{vars}(arr)

    ComponentVector(t)
end

include("grid_cell_domain.jl")

