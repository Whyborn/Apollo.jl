"""
    ScienceModule

The top level science module type, which acts as a fallback when methods are not implemented for specific science modules.
"""
abstract type ScienceModule end

# Define all the generic fallback methods. Most of these are methods that *must* be defined by the actual implementations, so throw errors if they ever reach the generic methods.
"""
    define_dimensions(dims, mod::ScienceModule, surface::SurfaceClass)

Fallback method for define_dimensions. It is allowed for a module to not define additional dimensions. 
"""
define_dimensions(dims, mod::ScienceModule, surface::SurfaceClass) = nothing

"""
    required_parameters(mod::ScienceModule, surface::SurfaceClass)

Fallback method for required_parameters. A module *must* define which parameters are required for its operation, so this throws an error.
"""
function required_parameters(mod::ScienceModule, surface::SurfaceClass)
    msg = "The implementation $(typeof(mod)) does not define which parameters are required for operation."
    error(msg)
end

"""
    required_forcing(mod::ScienceModule, surface::SurfaceClass)

Fallback method for required_forcing. A module *must* define which forcings are required for its operation, so this throws an error.
"""
function required_forcing(mod::ScienceModule, surface::SurfaceClass)
    msg = "The implementation $(typeof(mod)) does not define which forcings are required for operation."
    error(msg)
end

"""
    state_variables(mod::ScienceModule, surface::SurfaceClass)

Fallback method for state_variables. A module *must* define the state variables required for its operation, so this throws an error.
"""
function state_variables(mod::ScienceModule, surface::SurfaceClass)
    msg = "The implementation $(typeof(mod)) does not define which state variables are required for operation."
    error(msg)
end

"""
    dependent_variables(mod::ScienceModule, surface::SurfaceClass)

Fallback method for dependent_variables. A module *must* define the dependent variables required for its operation, so this throws an error.
"""
function dependent_variables(mod::ScienceModule, surface::SurfaceClass)
    msg = "The implementation $(typeof(mod)) does not define which dependent variables are required for operation."
    error(msg)
end

"""
    (mod::ScienceModule)(state_vars, update, dep_vars, parameters, forcing, domain)

Fallback callable for the given implementation. This should update variables in the `update` and `dep_vars` arrays.
"""
function (mod::ScienceModule)(state_vars, update, dep_vars, parameters, forcing, domain)
    msg = "The implementation $(typeof(mod)) has not defined its callable. Every implementation must define its callable with `function(mod::<Implementation>)(state_vars, update, dep_vars, parameters, forcing, domain)`."
    error(msg)
end

# Now metadata definitions, to assist with inspection of the implementations.

"""
    description(mod::ScienceModule)

Fallback method for the implementation description. An implementation must define a description, so this throws an error.
"""
function description(mod::ScienceModule)
    msg = "The implementation $(typeof(mod)) has not provided a description. Every implementation must define a description."
    error(msg)
end

"""
    authors(mod::ScienceModule)

Return the authors of the given implementation. `details` is a set of author strings or author => contact pairs.
"""
authors(mod::ScienceModule) = ("No authors provided",)

"""
    citation(mod::ScienceModule)

Return the Digital Object Identifier (DOI) associated with this implementation. Intended to capture the publication associated with the developing and testing of the implementation. Use references(mod) to list the existing works that the implementation is based on.
"""
citation(mod::ScienceModule) = "No citation provided."

"""
    references(mod::ScienceModule)

Return the DOI(s) which the implementation is based on. Use citation(mod) to provide the publication describing the implementation, if it is a new formulation.
"""
references(mod::ScienceModule) = ["No references provided."]

"""
    show(io, mime::MIME"text/plain", obj::ScienceModule)

Provide a detailed description of the module.
"""
function show(io, mime::MIME"text/plain", mod::ScienceModule)
    show(io, mod)
end

function show(io, mod::ScienceModule)
    print(io, "$(supertype(obj)) implementation: $(typeof(mod))\n\n")
    print(io, "Description:\n$(description(mod))\n\n")
    print(io, "Authors:\n")
    for author in authors(mod)
        if author isa pair
            name, email = author
            print(io, "\t$(name), contact: $(email)\n")
        elseif author isa String
            print(io, "\t$(name)\n")
        else
            error("Invalid return signature for authors(mod::$(typeof(mod))). Must be an iterable of String or String => String pairs.")
        end
    end
    print(io, "\n")
    print(io, "Citation: $(citation(mod))\n")
    print(io, "References:\n")
    for reference in references(mod)
        print(io, "\t$(reference)\n")
    end
    print(io, "\n")
end
