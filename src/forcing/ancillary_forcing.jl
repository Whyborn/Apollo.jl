"""
    AncillaryForcing{N, T, DT, AggType}
        CDM_var::String
        preload::Int
        times::Vector{DT}
        data::Array{N, T}
        loaded_range::UnitRange
    end

A wrapper around a Common Data Model file to facilitate agnostic access patterns within the model.
"""

mutable struct AncillaryForcing{AggType, TimeType, InterpType} <: Forcing
    CDM_var::CommonDataModel.AbstractVariable
    times::Vector{Dates.AbstractDateType}
    loaded_range::UnitRange
    data::Array
    preload::Int
end

function AncillaryForcing(dataset, CDM_name, t_start, agg_method, time_method, t_start, preload=0)
    cdm_var = ds[CDM_name].var

    # If preload isn't specified (i.e. is zero), then preload based on chunks if specified
    if preload == 0
        method, chunksizes = chunking(ds[CDM_name])
        if method == :chunked
            preload = chunksizes[end]
        else
            preload = 50
        end
    end

    # Don't want to continually reload the time data
    times = Array(ds["time"])

    # Assign the size of the stored data
    arr_size = (size(cdm_var)[1:end-1]..., preload)
    data = zeros(eltype(cdm_var), arr_size)
    
