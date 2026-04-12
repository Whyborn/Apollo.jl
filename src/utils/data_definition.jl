"""
    struct DataDefinition
        standard_name::String
        long_name::String
        units::String
        cell_methods::String
        shape::Tuple
        description::String
        other_attrs::Dict{String, String}
    end

A descriptor for data in the model. Used for creating the backing data, providing text descriptions and generating NetCDF variables.
"""

struct DataDefinition
    standard_name::String
    long_name::String
    units::String
    cell_methods::String
    shape::Tuple
    description::String
    other_attrs::Dict{String, Any}
end

function DataDefinition(;
        standard_name=nothing,
        long_name="no long_name provided",
        units=nothing,
        cell_methods="no cell_methods provided",
        shape=nothing,
        description=nothing,
        kwargs...
    )

    # Treat the required args
    if isnothing(standard_name)
        error("Every DataDefinition must define a `standard_name`.")
    end

    if isnothing(units)
        error("Every DataDefinition must define its `units`.")
    end

    if isnothing(shape)
        error("Every DataDefinition must define its `shape`.")
    end

    if isnothing(description)
        error("Every DataDefinition must provide a `description`.")
    end

    # Convert the kwargs to Dict{String, Any}
    other_attrs = Dict(String(k) => v for (k, v) in pairs(kwargs))

    return DataDefinition(standard_name, long_name, units, cell_methods, shape, description, other_attrs)
end
