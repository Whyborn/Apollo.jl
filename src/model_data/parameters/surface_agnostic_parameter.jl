abstract type AgnosticParameterValue <: ParameterValue end
"""
    struct HomogeneousScalarAgnosticParameter{T} <: AgnosticParameterValue
        value::T
    end

A parameter which has a constant global singleton value.
"""
struct HomogeneousScalarAgnosticParameter{T} <: AgnosticParameterValue
    value::T
end

function HomogeneousParameter(value::T) where {T <: Number}
    HomogeneousScalarAgnosticParameter{T}(value)
end

"""
Create parameter data for a homogeneous scalar surface agnostic parameter.
"""
function create_parameter_data(param_value::HomogeneousScalarAgnosticParameter{T}, param_def, model_dims)
    if () == param_def.dimensions
        # A parameter that is expected to be a single value
        values = param_value.value
    elseif :spatial in param_def.dimensions
        # Must be a spatial parameter, broadcast over space
        if :x in keys(model_dims)
            # Must be a gridded domain
            values = ones(T, (model_dims[:x], model_dims[:y])) * param_value.value
        else
            # Must be a site domain
            values = ones(T, model_dims[:site]) * param_value.value
        end
    else
        error("The $(param_def.internal_name) parameter was expected to have dims $(param_def.dimensions), but a scalar was supplied.")
    end

    return param_def.internal_name => values
end

"""
    struct HomogeneousArrayAgnosticParameter{T} <: AgnosticParameterValue
        value::T
    end

A parameter which has a constant global array value.
"""
struct HomogeneousArrayAgnosticParameter{N, T} <: AgnosticParameterValue
    value::Array{N, T}
end

function HomogeneousParameter(value::Array{N, T}) where {T <: Number, N}
    HomogeneousArrayAgnosticParameter{T, N}(value)
end

"""
Create parameter data for a homogeneous array surface agnostic parameter.
"""
function create_parameter_data(param_value::HomogeneousArrayAgnosticParameter{T}, param_def, model_dims)
    # Check that the leading dimensions are correct
    expected_shape = (model_dims[d] for d in param_def.dimensions if d != :spatial)
    if size(param_value.value) != expected_shape
        error("The $(param_def.internal_name) parameter was expected to have size $(expected_shape), but size $(size(param_value.value)) was supplied.")
    end

    # Now broadcast it if necessary
    if :spatial in param_def.dimensions
        if :x in model_dims
            # Gridded domain
            outer_repeat = (Tuple(1 for d in param_def.dimensions[1:end-2])..., model_dims[:x], model_dims[:y])
            values = repeat(param_value.value, outer=outer_repeat)
        else
            # Site domain
            outer_repeat = (Tuple(1 for d in param_def.dimensions[1:end-1])..., model_dims[:site])
            values = repeat(param_value.value, outer=outer_repeat)
        end
    else
        values = param_value.value
    end

    return param_def.internal_name => values
end

"""
    struct HeterogeneousScalarAgnosticParameter{T, N} <: AgnosticParameterValue
        value::Array{T, N}
    end

A parameter which has a spatially varying global singleton value.
"""
struct HeterogeneousScalarAgnosticParameter{T, N} <: AgnosticParameterValue
    value::Array{T, N}
end

function HeterogeneousParameter(value::Array{T, N}) where {T <: Number, N}
    HeterogeneousScalarAgnosticParameter{T, N}(value)
end

"""
    struct HeterogeneousArrayAgnosticParameter{T, N} <: AgnosticParameterValue
        value::T
    end

A parameter which has a spatially varying global array value.
"""
struct HeterogeneousArrayAgnosticParameter{N, T} <: AgnosticParameterValue
    value::Array{N, T}
end

function HeterogeneousParameter(value::Array{N, T}) where {T <: Number, N}
    HeterogeneousArrayAgnosticParameter{T, N}(value)
end
