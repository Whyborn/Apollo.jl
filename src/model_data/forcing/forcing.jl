abstract type Forcing end

# The possible time methods
abstract type TimeMethod end

struct RealTime <: TimeMethod end

struct RecycledTime <: TimeMethod
    start_time::Dates.AbstractDateTime
    end_time::Dates.AbstractDateTime
end

# The possible interpolation methods
abstract type InterpolationMethod end

struct LinearInterpolation <: InterpolationMethod end
struct NearestNeighbour <: InterpolationMethod end

include("ancillary_forcing.jl")
include("functional_forcing.jl")
