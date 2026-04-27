# The null implementation, which is the default for all non-specified implementations.
struct NullImplementation <: ScienceModule end

required_parameters(mod::NullImplementation, surface::SurfaceClass) = ()
required_forcing(mod::NullImplementation, surface::SurfaceClass) = ()
state_variables(mod::NullImplementation, surface::SurfaceClass) = ()
dependent_variables(mod::NullImplementation, surface::SurfaceClass) = ()

function (mod::NullImplemenetation)(surface::SurfaceClass, state_vars, update, dep_vars, parameters, forcing, domain)
    nothing
end

function description(mod::NullImplementation, surface::SurfaceClass)
    return "The NullImplementation is the fallback implementation if no implementation is specified for a particular module/surface combination."
end
