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
    parse_parameter(param_value, param_def, surface, domain)

Take the given `param_value` and convert it to a broadcastable value for the specified surface type.
"""
function parse_parameter(param_value::GlobalParameterValueScalar, param_def, surface, domain, dimensions)
    expected_dims = Tuple(dimensions[dim] for dim in param_def.dimensions)
    @assert param_def.dimensions == () "The parameter $(param_def.internal_name) is expected to have local size $(expected_dims), but a scalar was supplied."
    param_value.value
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


function parse_parameter(param_value::GlobalParameterValueArray{T, N}, param_def, surface, domain, dimensions)
    expected_dim_sizes = Tuple(dimensions[dim] for dim in param_def.dimensions)
    @assert expected_dim_sizes == size(param_value.value) "The parameter $(param_def.internal_name) is expected to have local size $(expected_dim_sizes), but passed parameter size is $(size(param_value.value))."

    Ref(param_value.value)
end


"""
    struct GlobalTiledParameterValue{T, N} <: ParameterValue
        value::Array{T, N}
        mapping::Dict
    end

Defines a parameter that is constant globally and heterogeneous across surface types. The mapping defines which slice of the array is assigned to the specific surface.
"""
struct GlobalTileParameterValue{T, N} <: ParameterValue
    value::Array{T, N}
    mapping::Dict
end

function parse_parameter(param_value::GlobalTileParameterValue{T, N}, param_def, surface, domain, dimensions)
    expected_dim_sizes = Tuple(dimensions[dim] for dim in param_def.dimensions)
    local_size = size(param_value.value)[1:end-1]
    @assert expected_dim_sizes == local_size "The parameter $(param_def.internal_name) is expected to have local size $(expected_dim_sizes), but passed parameter size is $(local_size)."

    # Select the slice for the surface
    for_surface = selectdim(param_value.value, ndims(param_value.value), param_value.mapping[surface])

    Ref(for_surface)
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
    GlobalParameterValue(value, mapping)

Define a scalar or array valued parameter that is constant in space, but different across surface types.
"""
function GlobalParameterValue(value::Array{T, N}, mapping::Dict) where {T, N}
    GlobalTileParameterValue(value, mapping)
end


"""
    struct SpatialParameterValue{T, N} <: ParameterValue
        value::Array{T, N}
    end

Defines a parameter that is spatially varying and homogeneous across surface types.
"""
struct SpatialParameterValue{T, N} <: ParameterValue
    value::Array{T, N}
end


function parse_parameter(param_value::SpatialParameterValue, param_def, surface, domain, dimensions)
    expected_dim_sizes = Tuple(dimensions[dim] for dim in param_def.dimensions)

    # Check that the spatial domain is the correct size
    check_spatially_compatible(param_value.value, domain)

    # Project the parameter array onto the land surface
    surface_array = project_onto(param_value.value, domain, surface)
    local_size = size(surface_array)[1:end-1]
    @assert expected_dim_size == local_size "The parameter $(param_def.internal_name) is expected to have local size $(expected_dim_size), but has local size $(local_size)."

    # Turn it into slices so it's broadcastable over land
    eachslice(surface_array, dims=ndims(surface_array))
end


"""
    struct SpatialTileParameterValue{T, N} <: ParameterValue
        value::Array{T, N}
        mapping::Dict
    end

Defines a parameter that is spatially varying and heterogeneous across surface types.
"""
struct SpatialTileParameterValue{T, N} <: ParameterValue
    value::Array{T, N}
    mapping::Dict
end


function parse_parameters(param_value::SpatialTileParameterValue, param_def, surface, domain, dimensions)
    expected_dim_sizes = Tuple(dimensions[dim] for dim in param_def.dimensions)

    # Select the slice for the surface
    for_surface = selectdim(param_value.value, ndims(param_value.value), param_value.mapping[surface])

    # Check that the spatial domain is the correct size
    check_spatially_compatible(for_surface, domain)

    # Project it onto the surface
    surface_array = project_onto(for_surface, domain, surface)
    local_size = size(surface_array)[1:end-1]
    @assert expected_dim_size == local_size "The parameter $(param_def.internal_name) is expected to have local size $(expected_dim_size), but has local size $(local_size)."

    # Turn it into slices so it's broadcastable
    eachslice(surface_array, ndims(surface_array))
end


"""
    function SpatialParameterValue(value, mapping)

Define a scalar or array valued parameter that is varying in space and different across surface types.
"""
function SpatialParameterValue(value, mapping)
    SpatialTileParameterValue(value, mapping)
end
