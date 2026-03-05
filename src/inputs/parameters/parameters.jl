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
