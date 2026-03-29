"""
A TileParameter sets the the given parameter to be defined based on the surface type.
"""
struct TileParameter <: AbstractParameter
    fn::Function
end

"""
A SpatialTileParameter sets the given parameter to be defined by both the surface type and it's coordinate on the domain.
"""
struct SpatialTileParameter <: AbstractParameter
    fn::Function
end

"""
Set the values for the TileParameter based on the user specified function, and broadcast it to the desired shape.
"""
function set_parameter(param::SpatialTileParameter, surface, domain)
    # We use a ref here, as there may be parameters that have additional
    # dimensions e.g. soil parameters that very with depth, and the
    # intention is to call physics routines across all tile points with
    # fn.(args...). This would break if this globally constant value was
    # actually an array- it would try to broadcast across this additional
    # dimension.
    Ref(param.fn(surface))
end

function set_parameter(param::TileParameter, surface, domain)
    # The above mentioned issue of broadcasting is not an issue here-
    # if the parameter has additional dimensions, the returned value
    # is an array of arrays, with the outermost array still being the
    # tile points array, so it will still broadcast the innermost array
    # correctly.
    points = tile_coords(domain, surface)

    param.fn.(surface, points)
end
