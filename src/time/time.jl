struct TimeDomain{T}
    start_time::T
    end_time::T
    timestep::Period
    max_run_time::Period
    convergence_fn::Function
end

# The default convergence function which always returns true
return_true(prev_state, curr_state) = true

"""
    TimeDomain(; start_time=nothing, timestep=nothing, end_time=nothing, max_run_time=Day(7), convergence_fn=return_true)

Initialise the time domain for a simulation.
"""
function TimeDomain(;
        start_time=nothing,
        timestep=nothing,
        end_time=nothing,
        max_run_time=Day(7),
        convergence_fn=return_true
    )
    # The required arguments are initialised as nothing
    if isnothing(start_time)
        error("start_time is required when defining a time domain.")
    end

    if isnothing(timestep)
        error("timestep is required when defining a time domain.")
    elseif !(timestep isa Period)
        error("timestep must be a period.")
    end

    if isnothing(end_time)
        error("end_time is required when defining a time domain.")
    end

    Timestep(start_time, end_time, timestep, max_run_time, convergence_fn)
end
