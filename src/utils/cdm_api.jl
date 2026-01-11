"""
    TemporalForcing{N, T, DT, AggType}
        CDM_var::String
        preload::Int
        times::Vector{DT}
        data::Array{N, T}
        loaded_range::UnitRange
    end

A wrapper around a Common Data Model file to facilitate agnostic access patterns within the model.
"""

mutable struct TemporalForcing{VarType, T, N, DateType, AggType}
    CDM_var::VarType
    preload::Int
    times::Vector{DateType}
    loaded_range::UnitRange
    data::Array{T, N}
end

"""
    TemporalForcing(ds, CDM_name, domain::Domain{T}, method, t_init, preload=0)

Initialise a new TemporalForcing accessor from the specified dataset `ds`, which targets
the specified variable `CDM_name`. The dataset `ds` can be any `CommonDataModel` file format.

The `domain` is any defined domain e.g. `GridCellDomain`, `SurfaceTypeDomain`, `VegetationDomain`.
The specified `CommonDataModel` variable must have shape compatible with the specified domain.

The 'method' describes the temporal aggregation method of the forcing i.e. a forcing which is a sum over a
period (like rainfall) should be treated different to instantaneous or time-averaged quantities (like wind).
Possible methods are `AggSum()`, `AggMean()`, `AggInstantaneous()`.

The start time for the forcing is set to `t_init`. The `preload` specifies how many time slices
should be preloaded for each new disk access, and defaults to the temporal chunk size. On initialisation,
`preload` time slices are loaded, starting at `t_init`, and are read from until the desired time leaves
the domain covered by the preloaded data, when a new set of `preload` time slices are loaded. The `preload`
effectively defines a trade-off between memory usage and compute efficiency.
"""
function TemporalForcing(ds, CDM_name::String, method, t_init, preload=0)
    cdm_var = ds[CDM_name].var

    # If preload isn't specified (i.e. is zero), then preload based on chunks if specified
    if preload == 0
        method, chunksizes = chunking(ds[CDM_name])
        if method == :chunked
            preload = chunksizes[end]
        else
            preload = 1
        end
    end

    # Get the time data
    times = Array(ds["time"])

    # Assign the size of the stored data
    arr_size = (size(cdm_var)[1:end-1]..., preload)
    data = zeros(eltype(cdm_var), arr_size)

    forcing = TemporalForcing{typeof(cdm_var), eltype(cdm_var), ndims(cdm_var), eltype(times), typeof(method)}(cdm_var, preload, times, 0:0, data)

    # Fill the initial set of data
    load_data!(forcing, t_init)

    forcing
end

export TemporalForcing

function load_data!(forcing, t)
    index = findfirst(x -> x >= t, forcing.times) - 1

    # Is the desired data already loaded?
    if index >= forcing.loaded_range.stop
        # Load new data in
        if index + forcing.preload <= length(forcing.times)
            # We can fit all the data into the array
            t_range = index:(index + forcing.preload - 1)
        else
            # The current index + preload steps over the end of the array
            t_range = (length(forcing.times) - forcing.preload + 1):length(forcing.times)
        end
        CommonDataModel.load!(forcing.CDM_var, forcing.data, Tuple((:) for _ in 1:ndims(forcing.data)-1)..., t_range)
        forcing.loaded_range = t_range
    end

    index
end

"""
    get_data!(arr, forcing::TemporalForcing, time, dt)

Load the data for the specific 'time' from the specified forcing data in place into the array `arr`.
"""
function get_data!(arr, forcing::TemporalForcing, time, dt)
    index = load_data!(forcing, time)
    
    # Compute the weights and which index in the loaded data to use
    t_m1_data_ind, t_p1_data_ind, t_m1_weight, t_p1_weight = compute_weights(forcing, index, time, dt)

    # Compute the data
    arr .= t_m1_weight * get_data(forcing, t_m1_data_ind) + t_p1_weight * get_data(forcing, t_p1_data_ind)
end

"""
    compute_weights(forcing, index, time, dt)

Compute the indices of the data to retrieve from the `forcing` and their respective weights.
"""
function compute_weights(forcing::TemporalForcing{VT, T, N, DT, AggMethod}, index, time, dt) where {VT, N, T, DT, AggMethod <: Union{AggInstantaneous, AggMean}}
    t_m1 = forcing.times[index]
    t_p1 = forcing.times[index+1]

    t_m1_weight = (time - t_m1) / (t_p1 - t_m1)
    t_p1_weight = 1 - t_m1_weight

    t_m1_data_ind = index - forcing.loaded_range.start + 1
    t_p1_data_ind = t_m1_data_ind + 1

    t_m1_data_ind, t_p1_data_ind, t_m1_weight, t_p1_weight
end

function compute_weights(forcing::TemporalForcing{VT, T, N, DT, AggMethod}, index, time, dt) where {VT, N, T, DT, AggMethod <: AggSum}
    t_m1 = forcing.times[index]
    t_p1 = forcing.times[index+1]

    forcing_dt = t_p1 - t_m1
    ts_mid = 0.5 * (t_m1 + t_p1)

    dt_frac_of_forcing_dt = dt / forcing_dt
    t_m1_weight = min((ts_mid - time) / dt, 1.0) * dt_frac_of_forcing_dt
    t_p1_weight = min((time + dt - ts_mid) / dt, 1.0) * dt_frac_of_forcing_dt

    t_m1_data_ind = index - forcing.loaded_range.start + 1
    t_p1_data_ind = t_m1_data_ind + 1

    t_m1_data_ind, t_p1_data_ind, t_m1_weight, t_p1_weight
end

"""
    get_data(forcing, index)

Return the a view of the data slice at the given time index.
"""
function get_data(forcing::TemporalForcing{VT, T, 3, DT, A}, ind) where {VT, T, DT, A}
    @view(forcing.data[:, :, ind])
end

function get_data(forcing::TemporalForcing{VT, T, 4, DT, A}, ind) where {VT, T, DT, A}
    @view(forcing.data[:, :, :, ind])
end
