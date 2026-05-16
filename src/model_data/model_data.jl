"""
    check_data_meta(internal_name, data_kwargs)

Ensures that the metadata attached to the `internal_name` data, contained in `data_kwargs`, is valid.

Valid metadata contains `standard_name`, `units` and `description`. Optional entries are `long_name` and `dimensions`, which are assigned default values of `"no long_name supplied"` and `()` respectively if they are not defined.
"""
function check_data_meta(internal_name, data_kwargs)
    bad_meta = false
    err_msgs = String[]
    if !haskey(data_kwargs, "standard_name")
        push!(err_msgs, "No standard name supplied.")
        bad_meta = true
    end

    if !haskey(data_kwargs, "units")
        push!(err_msgs, "No units supplied.")
        bad_meta = true
    end

    if !haskey(data_kwargs, "description")
        push!(err_msgs, "No description supplied.")
        bad_meta = true
    end

    if bad_meta
        msg = "The internal data $(internal_name) has invalid metadata. The problems are:\n"
        for m in err_msgs
            msg *= "\t$(m)"
        end
    end

    data_kwargs["long_name"] = get(data_kwargs, "long_name", "no long_name supplied")
    data_kwargs["dimensions"] = get(data_kwargs, "dimensions", ())
end

"""
    add_model_dimension!(model_dims, new_dim, dim_size)

Add the model dimension with the name `new_dim` with length `dim_size` to the model dimensions.
"""
function add_model_dimension!(model_dims, science_module, surface)
    for new_dim in dimensions(science_module, surface)
        if haskey(model_dims, new_dim) && model_dims[new_dim] != dim_size
            error("The dimension $(new_dim) has conflicting sizes: $(dim_size) vs $(model_dims[new_dim])")
        end

        model_dims[new_dim] = dim_size
    end
end

include("parameters/parameter.jl")

