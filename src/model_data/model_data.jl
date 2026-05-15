"""
    check_data_meta(kwargs)

Upon construction of any internal data, some metadata must be supplied at the call site. This function makes sure the required metadata is specified, and gives default values to any that aren't.
"""
function check_data_meta(internal_name, kwargs)
    bad_meta = false
    err_msgs = String[]
    if !haskey(kwargs, "standard_name")
        push!(err_msgs, "No standard name supplied.")
        bad_meta = true
    end

    if !haskey(kwargs, "units")
        push!(err_msgs, "No units supplied.")
        bad_meta = true
    end

    if !haskey(kwargs, "description")
        push!(err_msgs, "No description supplied.")
        bad_meta = true
    end

    if bad_meta
        msg = "The internal data $(internal_name) has invalid metadata. The problems are:\n"
        for m in err_msgs
            msg *= "\t$(m)"
        end
    end

    kwargs["long_name"] = get(kwargs, "long_name", "no long_name supplied")
    kwargs["dimensions"] = get(kwargs, "dimensions", ())
end

"""
    add_model_dimension!(model_dims, new_dim, dim_size)

Add the model dimension with the name `new_dim` with length `dim_size` to the model dimensions.
"""
function add_model_dimension!(model_dims, new_dim, dim_size)
    if haskey(model_dims, new_dim) && model_dims[new_dim] != dim_size
        error("The dimension $(new_dim) has conflicting sizes: $(dim_size) vs $(model_dims[new_dim])")
    end

    model_dims[new_dim] = dim_size
end

include("parameters/parameter.jl")

