## User Facing Components

### Time Domain

The time domain is defined by 5 quantities, 2 of which are optional:

* The start time. The type of the start time defines the calendar used in the model. The Julia `CFTime` package defines each of the calendars specified in the CF standards, through:
    - `DateTimeStandard`: Standard Gregorian calendar.
    - `DateTimeJulian`: Julian calendar.
    - `DateTimeProlepticGregorian`: Proleptic Gregorian calendar.
    - `DateTimeAllLeaps`: Every year is a leap year.
    - `DateTimeNoLeaps`: No leaps years.
    - `DateTime360Day`: 360 day calendar with 30 day months.
* The timestep, which is a `Period` type.
* The end time, which must be the same time type as the start time.
* The maximum run time, which is a `Period` type, which dictates how long the simulation is allowed to run in real time. This is checked at the end of each simulation day. This is optional, defaults to (effectively) infinite time.
* A convergence condition. If the convergence condition is not yet when the simulation time hits the end time, then the time is restarted but the state remains the same. Useful for spinning up the model. This is optional, defaults to always `true`.

The convergence condition takes the model state at the start and end of the most recent time cycle as inputs, and returns a boolean.

An example construction of a `TimeDomain` is:

```julia
td = TimeDomain(
        start_time=DateTimeStandard(1950, 1, 1),
        timestep=Minutes(60),
        end_time=DateTimeStandard(2000, 1, 1),
        max_run_time=Hours(5),
        convergence_condition=conv_fn
        )
```

This simulation would begin at the start of 1950 and end at the end of 1999, run using a standard gregorian calendar with a base timestep of 60 minutes for a maximum of 5 hours. The the `conv_fn` does not return `true` at the end of a cycle, it will reset the time to 1950 and run through again.

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

To inspect the traits required for a given surface type, use:

```julia
required_traits(::SurfaceType)
```

#### Spatial Domain

The spatial domain is defined by an array of land fractions with associated coordinates, a mapping of concrete surface types to the land fractions and optionally a land mask. If the provided land fractions array is 2D, then the domain is assumed to be a site domain, and a gridded domain for 3D land fractions.

The mapping is a dictionary which describes which pages of the land fractions correspond to each land surface type:

```julia
mapping = Dict(
    EvergreenBroadleaf => 1,
    DeciduousBroadleaf => 2,
    Grass => (3, 4),
    Lake => 5
    )
```

In this mapping, the first page of the land fractions is assigned to `EvergreenBroadleaf`, the second to `DeciduousBroadleaf`, third and fourth to `Grass` and fifth to `Lake`. It is allowed to exclude pages from the mapping.

An example domain initialisation would be:

```julia
dom = SimDomain(lons, lats, land_fractions, mapping)
```

If `land_fractions` is a 2D array, then this is a site domain, and the `lons` and `lats` must be the same length and of equal length to the first dimension of the `land_fractions`. If `land_fractions` is a 3D array, then this is a gridded domain, and the `lons` must be the same size as the first dimension of `land_fractions` and `lats` the same as the second.

### Defining the Science

The science is split into modules, each having at least 1 implementation. Each module defaults to the null implementation, which does nothing. The simulation science is defined by:

```julia
sim_science = ScienceDefinition(
        SoilMoistureThermodynamics=SharedMultiLayer(layers=10),
        Canopy=CanopyModel(),
        Urban=SimpleUrban(),
        Radiation=TwoBand(),
        Photosynthesis=PhotosynthesisModel
        )
```

### Defining the Parameters

Parameters are values which are unchanged through the duration of the simulation. The parameter definitions are prepared in a dictionary, with reserved key names for each parameter. There are two types of parameters:

* `SurfaceSpecificParameter`: A parameter which may have different values for each specific surface type.
* `SurfaceAgnosticParameter`: A parameter which has the same values for all surface types.

The `SurfaceSpecificParameter` takes an array or NetCDF variable as input, alongside a mapping describing which pages of the array to apply to which surface type. The slowest varying dimension of the array (i.e. the rightmost) is assumed to be the surface slicing dimension. For example, to supply a global map of LAI to the vegetated surfaces, supply an array-like with shape `(nlon, nlat, M)` and a dictionary describing the relationship between the index `M` and the surface types like `Dict(EvergreenBroadleaf => 1, DeciduousBroadleaf => 2, ...)`. Note that is possible to map multiple surface types to the same index. The page of the array will be mapped onto the tile's working array for the parameter.

The `SurfaceAgnosticParameter` can take a scalar, array or NetCDF variable as input. The array will be mapped onto the land's working array for the parameter.

The parameters are added to a dictionary, which is passed to the model initialisation. The keys of the dictionary correspond to specific names for each parameter defined by the science modules. To determine which parameters are required by the model, use `required_parameters(<science_module>)` e.g. to see which parameters are required for the radiation model, use `required_parameters(TwoBand())`. You can also pass a `ScienceDefinition` to dump all the required parameters for all specified implementations.

### Defining the Forcing

Forcings are values which change through the duration of the simulation. These can be things that vary at the time step frequency e.g. atmospheric forcing, seasonal frequency e.g. leaf area index, or any other frequency. A forcing can be defined in two ways:

* `DataForcing`: Retrieve the forcing from an external dataset. This can be any dataset which follows the `CommonDataModel` specifications.
* `FunctionForcing`: Define the forcing using a function, which uses the current time and coordinates to return a scalar at a given space and time.

When using `DataForcing`, the data have the same leading dimensions as the size of the domain (whether that is site or gridded). The timestep will not necessarily be on the model timestep. This means the interpolation method for the dataset must be specified. The possible interpolation options are:

* `Nearest`: Take the nearest value in time.
* `Linear`: Perform linear interpolation between values.
* `Previous`: Take the most recent value.
* `Next`: Take the next value.

It is also necessary to specify what the temporal method of the forcing is, to allow correct handling of the interpolation. For example, precipitation is sometimes reported as a sum over the period, so if the model timestep is half the data timestep, then the precipitation would be effectively doubled if it were treated as a point value. To this end, the type of the forcing can be specified as:

* `Sum`
* `Point`



