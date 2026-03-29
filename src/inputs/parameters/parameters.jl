abstract type AbstractParameter end

include("spatial_parameters.jl")
include("tile_parameters.jl")

"""
Ensure that all of the parameters required by the physics module are defined by the user.
"""
function check_parameters(physics_mod, params, forcing, surface, domain)
    req_params = required_parameters(physics_mod)

    # For each required parameter, check that it's been given an
    # appropriate definition.
    for (req_param, req_shape) in req_params
        if !hasproperty(params, req_param)
            # Check whether it's been upgraded to a forcing
            @assert hasproperty(forcing, req_param) "The parameter $(req_param), which is required by the $(physics_mod) module, has not been defined on the $(surface) surface."

            # Check if it's the right shape
            @assert req_shape == size(getproperty(forcing, req_param)) "The expected shape for the $(req_param) parameter is $(req_shape), but the supplied shape on the $(surface) surface is $(size(getproperty(params, req_param)))"
        end

        # It is a parameter, is it the right shape?
        @assert req_shape == size(getproperty(params, req_param)) "The expected shape for the $(req_param) parameter is $(req_shape), but the supplied shape on the $(surface) surface is $(size(getproperty(params, req_param)))"
    end

end

"""
Evaluate the parameter values for each parameter required by the physics module, if not already defined by another module.
"""

function evaluate_parameters(physics_mod, param_values, input_params, surface, domain)
    
    # Which parameters does the module require?
    req_params = required_parameters(physics_mod, surface)

    for req_param in req_params
        if haskey(param_values, req_param)
            # Just check that there's no mismatch between what the two modules want.
        else
            param_values[req_name] = set_parameter(input_params[req_params], surface, domain)
    end
end
