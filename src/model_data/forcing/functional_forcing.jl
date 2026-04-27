"""
    struct FunctionalForcing{AggType, TimeType} <: Forcing
        func::Function
        data::Array
    end

Define a forcing with a functional definition.
"""

function FunctionalForcing(f, agg_method::AggType, time_method::TimeType, domain::Domain) where {AggType <: AggregationMethod, TimeType <: TimeMethod}

    


