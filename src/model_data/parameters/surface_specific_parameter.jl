abstract type SpecificParameterValue
"""
    struct HomogeneousScalarSpecificParameter{T} <: SpecificParameterValue
        value::T
    end

A parameter which has a constant global singleton value on each specific surface type.
"""
struct HomogeneousScalarSpecificParameter{T} <: SpecificParameterValue
    value::Vector{T}
    mapping::Dict
end

function HomogeneousParameter(value::Vector{T}, mapping) where {T <: Number}
    HomogeneousScalarSpecificParameter{T}(value, mapping)
end

"""
    struct HomogeneousArraySpecificParameter{T} <: SpecificParameterValue
        value::T
    end

A parameter which has a constant global array value.
"""
struct HomogeneousArraySpecificParameter{N, T} <: SpecificParameterValue
    value::Array{N, T}
    mapping::Dict
end

function HomogeneousParameter(value::Array{N, T}, mapping) where {T <: Number, N}
    HomogeneousArraySpecificParameter{T, N}(value, mapping)
end

"""
    struct HeterogeneousScalarSpecificParameter{T, N} <: SpecificParameterValue
        value::Array{T, N}
    end

A parameter which has a spatially varying global singleton value.
"""
struct HeterogeneousScalarSpecificParameter{T, N} <: SpecificParameterValue
    value::Array{T, N}
    mapping::Dict
end

function HeterogeneousParameter(value::Array{T, N}, mapping) where {T <: Number, N}
    HeterogeneousScalarSpecificParameter{T, N}(value, mapping)
end

"""
    struct HeterogeneousArraySpecificParameter{T, N} <: SpecificParameterValue
        value::T
    end

A parameter which has a spatially varying global array value.
"""
struct HeterogeneousArraySpecificParameter{N, T} <: SpecificParameterValue
    value::Array{N, T}
    mapping::Dict
end

function HeterogeneousParameter(value::Array{N, T}, mapping) where {T <: Number, N}
    HeterogeneousArraySpecificParameter{T, N}(value, mapping)
end
