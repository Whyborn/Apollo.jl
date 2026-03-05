"""
A TileParameter sets the the given parameter to be defined based on the surface type.
"""
struct TileParameter <: AbstractParameter
    fn::Function
end

"""
Set the values for the TileParameter based on the user specified function, and broadcast it to the desired shape.
"""

function set_parameter(param::TileParameter, surface, domain)
    value = param.fn(surface)

    # The desired shape for the parameter may be multi-dimensional
