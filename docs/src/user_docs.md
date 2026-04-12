## User Facing Components

### Time Domain

The time domain is defined by 3 quantities:

* The start time. The type of the start time defines the calendar used in the model. The Julia `CFTime` package defines each of the calendars specified in the CF standards, through:
    - `DateTimeStandard`: Standard Gregorian calendar.
    - `DateTimeJulian`: Julian calendar.
- `DateTimeProlepticGregorian`: Proleptic Gregorian calendar.
    - `DateTimeAllLeaps`: Every year is a leap year.
    - `DateTimeNoLeaps`: No leaps years.
    - `DateTime360Day`: 360 day calendar with 30 day months.
* The timestep, which is a `Period` type.
* A end condition. There are three possible end conditions:
    - `SimTimeEndCondition`: Simulation stops when reaching a specific simulation time.
    - `RunTimeEndCondition`: Simulations stop after a set amount of run time (in real terms).
    - `ConvergenceEndCondition`: End when the model state has reached a seasonal equilibrium. Uses a user defined function to determine whether convergence has been achieved.

### Spatial Domain

The spatial domain is defined by a series of `SurfaceClass` types and a map describing where those surface types exist in space.

#### Surface Classes and Traits

The surface types are organised hierarchically. At the top, there is the generic `SurfaceClass`. Underneath this are the broad surface classifications: `Vegetated`, `Water`, `Ice`, `Urban` and `Bare`. This is as far as the model defines internally, and they are still abstract types, and cannot be instantiated. The user must define the concrete types which form the end of the type tree.

Given the model does not define the concrete types, there must still be a way of distinguishing behaviour of particular concrete surface types that fall under a single surface classification. This is achieved via [Traits](https://www.juliabloggers.com/the-emergent-features-of-julialang-part-ii-traits/). The traits available to a given surface classification are defined internally to the model.

We will demonstrate this with a `VegetatedSurface`. Vegetation will be treated differently depending on its phenology, whether it's woody biomass or its leave type. So when we define a new `VegetatedSurface`, we need to specify the value for each of these traits.

```julia
struct EvergreenBroadleaf <: VegetatedSurface
    internal_name::Symbol
end

phenology(::Type{EvergreenBroadleaf}) = Evergreen()
biomass(::Type{EvergreenBroadleaf}) = Woody()
leaf_type(::Type{EvergreenBroadleaf}) = Broadleaf()

egbl = EvergreenBroadleaf(:EvergreenBroadleaf)
```

Now this surface will behave according to these traits. A convenience constructor is supplied for this purpose:

```julia
egbl = @VegetatedSurface EvergreenBroadleaf phenology=evergreen biomass=woody leaf_type=broadleaf
```





