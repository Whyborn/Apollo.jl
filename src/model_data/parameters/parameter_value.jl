abstract type ParameterValue end

"""
    struct GlobalParameterValueScalar{T} <: ParameterValue
        value::C
    end

Defines a scalar parameter that is constant globally and homogeneous across surface types. The scalar and array representations are split so that we can concretize the numeric type of the parameter consistently.

Created via the GlobalParameterValue interface.
"""

struct GlobalParameterValueScalar{T} <: ParameterValue
    value::T
end

"""
    struct GlobalParameterValueArray{T, N} <: ParameterValue
        value::Array{T, N}
    end

Defines an array parameter that is constant globally and homogeneous across surface types. The scalar and array representations are split so that we can concretize the numeric type of the parameter consistently.

Created via the GlobalParameterValue interface.
"""
struct GlobalParameterValueArray{T, N} <: ParameterValue
    value::Array{T, N}
end

"""
    GlobalParameterValue(value)

Define a scalar or array valued parameter that is constant in space and across surface types.
"""
function GlobalParameterValue(value::T) where {T <: Number}
    GlobalParameterValueScalar(value)
end

function GlobalParameterValue(value::Array{T, N}) where {T <: Number, N}
    GlobalParameterValueArray(value)
end

"""
    parse_parameter(param_value, param_def, surface, domain)

Take the given `param_value` and convert it to a broadcastable value for the specified surface type.
"""
function parse_parameter(param_value::Union{GlobalParameterValueScalar, GlobalParameterValueArray}, param_def, surface, domain)
    Ref(param_value.value)
end

"""
    struct SpatialParameterValue{T, N} <: ParameterValue

Defines a parameter that is spatially varying and homogeneous across surface types.
"""
struct SpatialParameterValue{T, N} <: ParameterValue
    value::Array{T, N}
end

function parse_parameter(param_value::SpatialParameterValue, param_def, surface, domain)
    surface_map = get_surface_domain(surface, domain)

    arr_for_surface = zeros(eltype(param_value.value), (param_def.dimensions..., length(surface_map.inds)))

    arr_for_surface .= param_value
"""
    struct GlobalTiledParameterValue <: ParameterValue
        value::AbstractArray
        mapping::Dict
    end

Defines a parameter that is constant globally and heterogeneous across surface types. The mapping is a dictionary of `SurfaceType => Int` pairs which define which slice of the array is assigned to each surface type.
"""

struct GlobalTiledParameterValue{T, N} <: ParameterValue
    value::Array{T, N}
    mapping::Dict{SurfaceType, AbstractInt}
end


        
