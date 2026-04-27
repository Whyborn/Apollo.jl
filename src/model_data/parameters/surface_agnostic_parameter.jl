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

function validate_input(param_value::HomogeneousScalarAgnosticParameter, expected_size)
    

function create_internal_data(parameter::HomogeneousScalarAgnosticParameter, domain)
    return 
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
