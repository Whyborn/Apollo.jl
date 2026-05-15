"""
    struct ParameterDescription
        internal_name::Symbol
        standard_name::String
        long_name::String
        local_dimensions::Tuple
        units::String
        description::String
    end

The internal representation of a Parameter. Used to match up with the user-specified ParameterValues.
"""
struct ParameterDefinition <: ModelDataDefinition
    # Internal name used in the ComponentArray
    internal_name::Symbol
    # CF compliant (if applicable) standard name
    standard_name::String
    # CF compliant (if applicable) long name
    long_name::String
    # The dimensionality of the parameter on a surface grid cell
    local_dimensions::Tuple
    # Expected units of the parameter
    units::String
    # A description of what the parameter is
    description::String
end

function ParameterDefinition(internal_name; kwargs...)
    # Start by handling the kwargs that are required
    check_data_meta(internal_name, kwargs)

    Parameter(internal_name,
              kwargs["standard_name"],
              kwargs["long_name"],
              kwargs["dimensions"],
              kwargs["units"],
              kwargs["description"]
             )
end
