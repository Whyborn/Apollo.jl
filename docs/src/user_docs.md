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

### Domain

The spatial domain is defined by a series of `SurfaceClass` types and a map describing where those surface types exist in space.

#### Surface Classes and Traits

The surface types are organised hierarchically. At the top, there is the generic `SurfaceClass`. Underneath this are the broad surface classifications: `Vegetated`, `Water`, `Ice`, `Urban` and `Bare`. This is as far as the model defines internally, and they are still abstract types, and cannot be instantiated. The user must define the concrete types which form the end of the type tree.

Given the model does not define the concrete types, there must still be a way of distinguishing behaviour of particular concrete surface types that fall under a single surface classification. This is achieved via [Traits](https://www.juliabloggers.com/the-emergent-features-of-julialang-part-ii-traits/). The traits available to a given surface classification are defined internally to the model.

We will demonstrate this with a `VegetatedSurface`. Vegetation will be treated differently depending on its phenology and whether its stems are woody or herbaceous. So when we define a new `VegetatedSurface`, we need to specify the value for each of these traits.

```julia
struct EvergreenBroadleaf <: VegetatedSurface
    internal_name::Symbol
end

phenology(::Type{EvergreenBroadleaf}) = Evergreen()
biomass(::Type{EvergreenBroadleaf}) = Woody()

egbl = EvergreenBroadleaf(:EvergreenBroadleaf)
```

Now this surface will behave according to these traits. A convenience constructor is supplied for this purpose:

```julia
egbl = @VegetatedSurface EvergreenBroadleaf phenology=evergreen stems=woody
```

To inspect the traits required for a given surface type, use:

```julia
required_traits(::SurfaceType)
```

We will construct an example (with nonsense values) to demonstrate how to construct a simulation. Include some basic surface types:

```
egbl = @VegetatedSurface EvergreenBroadleaf phenology=evergreen stems=woody
c3g = @VegetatedSurface C3Grass phenology=evergreen stems=herbaceous
fixed_ice = @IceSurface FixedIce
lake = @WaterSurface Lake
barren = @BareSurface Barren
```

#### Spatial Domain

The spatial domain is defined by an array of land fractions with associated coordinates, a mapping of concrete surface types to the land fractions and optionally a land mask. If the provided land fractions array is 2D, then the domain is assumed to be a site domain, and a gridded domain for 3D land fractions.

We'll load up a non-existent land fractions dataset to demonstrate initialising the domain. Assume a 1 degree resolution global simulation.

```julia
test_ds = Dataset("imaginary_land_fracs.nc")
land_fractions = Array(test_ds["vegetation_area_fraction"])     # size(land_fractions) = (360, 180, 5)
```

Now we need The mapping is a dictionary which describes how the pages of `land_fractions` correspond to each land surface type:

```julia
mapping = Dict(
    EvergreenBroadleaf => 1,
    C3Grass => 2,
    FixedIce => 3,
    Lake => 4,
    Barren => 5
    )

simulation_domain = SimDomain(test_ds["lon"][:], test_ds["lat"][:], land_fractions, mapping)
```

In this mapping, `land_fractions[:, :, 1]` is assigned to `EvergreenBroadleaf`, `land_fractions[:, :, 2]` to `C3Grass` and so on. The `land_fractions` are 3D, so it is assumed to be a gridded domain. It is allowed to exclude pages from the mapping, for example if lakes were to be excluded from the simulation, then `land_fractions[:, :, 4]` would not be used at all. The land fractions do not need to add up to 1 on a grid cell, but if `normalise=true` is passed, then the resulting fractions will be normalised to 1.0. The mask is inferred from the land fraction sums- any grid cell with total 0.0 area is masked. It is possible to provide a land mask to directly control which points are included in the simulation.

### Defining the Science

The science is split into modules, each having at least 1 implementation. Implementations can be defined generically, for all `SurfaceClass` types, or defined separately for each surface class i.e. defined for `VegetatedSurface`, `IceSurface`, `WaterSurface`, `UrbanSurface` and `BareSurface`. The science implementations are contained in a `ScienceDefinition`:

```julia
sim_science = ScienceDefinition(
        SoilMoistureThermodynamics=SharedMultiLayer(layers=10),
        Canopy=Dict(VegetatedSurface => VegetatedCanopyModel(), Urban => UrbanCanopyModel())
        Radiation=TwoBand(),
        Photosynthesis=Dict(VegetatedSurface => PlantPhotosynthesisModel())
        )
```

In this instance, the soil moisture and thermodynamics as well as radiation utilise the same implementation for all of the surface classes. Note that this does *not* necessarily mean they are using an identical set of equations- it is possible for a given implementation to specify different behaviour for different classes. The canopy and photosynthesis have specified implementations for the `VegetatedSurface` and `Urban` surface classes- any surface classes not specified for a given science module will use the `NullImplementation`, which does nothing.

Each implementation is required to define a series of metadata methods:

* `description`: A scientific description of the implementation. Should include all equations used and a text desciption.
* `author`: A list of authors for the implementation. May include contact details of the author so chooses.
* `references`: A list of DOIs listing the publications used for the development of the implementation. May be empty if it is a novel implementation, in which case the `publication` should provide a DOI.
* `publication`: Reference publication DOI for the implementation. May be empty if the implementation comes from an existing work.
* `info`: Combination of all the above methods- prints the description, author, references and publication.

Note that both `references` and `publication` may be provided if the implementation is based on a previous work, with some novelties/improvements. Each of these can be called with the implementation as an argument e.g.

```
description(VegetatedCanopyModel)
author(VegetatedCanopyModel)
...
```

### Defining the Parameters

Parameters are values which are unchanged through the duration of the simulation. The parameter definitions are prepared in a dictionary, with reserved key names for each parameter. There are two types of parameters:

* Surface specific parameters: A parameter which may have different values for each specific surface type.
* Surface agnostic parameters: A parameter which has the same values for all surface types (either per grid cell or globally).

Both are constructed using the `Parameter` interface, with the difference being the inclusion of a `mapping` dictionary for surface specific parameters. The first input to the `Parameter` is always the source data. This can be a scalar, an array or any `CommonDataModel` variable. For surface agnostic parameters, this is the only input, while for surface specific parameters, an additional mapping dictionary is required, which maps the pages of the array to specific surface types.

The way in which the passed data is treated is inferred based off the dimensionality of the array. For surface agnostic variables, it is assumed that the "trailing" dimensions i.e. right-most and slowest varying, represent the spatial dimensions, either `(nlon, nlat)` or `(nsite)` *if there is a spatial dependence*. The leading dimensions are assumed to be the shape of the local parameter e.g. number of soil layers.

To demonstrate, consider a 1 degree global simulation, with `(nlon=360, nlat=180)`. If a parameter is specified with an array of shape `(360, 180)`, it's assumed that each grid cell gets a scalar value. If a parameter is specified with an array of shape `(6, 360, 180)`, it's assumed that each grid cell gets an array of shape `(6,)`. If it's specified with an array of shape `(6, 180)`, then it's assumed that each grid cell gets *the same array of shape `(6, 180)`*, since the trailing dimensions don't match the spatial domain.

The same rules apply to the surface specific variables, with the addition of a necessary trailing dimension for the surface types. This means the last dimension is *always* for the surface types, the next dimensions are the spatial dimensions *if there is a spatial dependence*, and any leading dimensions are parameter specific dimensions on the surface. The mapping specifies which slice of the array goes to which surface.

The parameters are specified in a dictionary which is then passed to the simulation preparation. Assuming the target domain is the example domain specified in the [Spatial Domain](#spatial-domain) section:

```julia
# A surface agnostic parameter
parameters[:gravity] = Parameter(9.81)                  # Constant value everywhere

# A surface agnostic spatially varying parameter
parameters[:surface_albedo] = Parameter(albedo_array)   # albedo_array is a (360, 180) size array, so different value on each grid cell

# Surface specific parameter, constant everywhere for each surface
param_mapping = Dict(EvergreenBroadleaf => 1, C3Grass => 2)
parameters[:max_carboxylation_rate] = Parameter(vcmax_values, mapping)    # A vector of length >= 2, with first value applied to EGBL and second to C3 grass.

# Surface specific parameter, spatially varying
parameters[:leaf_area_index] = Parameter(lai_array, mapping)    # lai_array is a (360, 180, M) array with M >= 2, with lai_array[:, :, 1] applied to EGBL etc.

# Surface specific parameter, constant in space but array valued
parameters[:root_fraction_in_layer] = Parameter(root_fracs, mapping)    # root_fracs is a (N, M) array with N = number of soil layers and M >= 2. EGBL gets [:, 1] etc.
```

In each of these instances, the array may be replaced with any `CommonDataModel` variable e.g. NetCDF, Zarr, GRIB, see [CommonDataModel](github.com/JuliaGeo/CommonDataModel.jl).

The parameters required by the model are defined by the constituent implementations in the `ScienceDefinition`. Use `required_parameters` to show which parameters are required for a given implementation. It will show the parameter desciption, the units and the expected data size of the parameter.

```julia
required_parameters(VegetatedCanopyModel())
```

### Defining the Forcing

Forcings are values which change through the duration of the simulation. These can be things that vary at the time step frequency e.g. atmospheric forcing, seasonal frequency e.g. leaf area index, or any other frequency. A forcing can be defined in two ways:

* `DataForcing`: Retrieve the forcing from an external dataset. This can be any dataset which follows the `CommonDataModel` specifications.
* `FunctionForcing`: Define the forcing using a function, which uses the current time and coordinates to return a scalar at a given space and time.

When using `DataForcing`, the data have the same leading dimensions as the size of the domain (whether that is site or gridded). The timestep will not necessarily be on the model timestep. This means the interpolation method for the dataset must be specified. The possible interpolation options are:

* `Nearest`: Take the nearest value in time.
* `Linear`: Perform linear interpolation between values.
* `Previous`: Take the most recent value.
* `Next`: Take the next value.

It is also necessary to specify what the temporal method of the forcing is to allow correct handling of the interpolation. This applies for both functional and data forcing. For example, precipitation is sometimes reported as a sum over the period, so if the model timestep is half the data timestep, then the precipitation would be effectively doubled if it were treated as a point value. To this end, the type of the forcing can be specified as:

* `Sum`: Data is an accumulation over the time interval.
* `Point`: Data is an instantaneous snapshot at the specified time.
* `Mean`: Data is the mean over the time interval.

The time period for the forcing can be set as either `RealTime`, which uses the actual simulation time for indexing, or `CyclicTime`, which recycles a specific period e.g. for spinning up a simulation. A `RealTime` forcing takes no arguments, while a `CyclicTime` forcing takes a start date and a period as arguments. The forcings required by the model are defined by the constituent implementations in the `ScienceDefinition`. Use `required_forcings` to show which parameters are required for a given implementation.

```julia
required_forcing(TwoBandRadiation())
```

#### Data Forcing

When using a `DataForcing`, the name of an external dataset and the target variable name within that dataset is required. The dimensionality is treated in the same way as the parameters, with the addition of the time axis as the rightmost (slowest varying) axis. So the assumed order of dimensions is `(<local dimensions>, <spatial dimensions>, <surface type dimension>, <time dimension>)`. The only dimension required is the time dimension- any others are optional, depending on the desired behaviour of the forcing.

The external dataset associated with a `DataForcing` *must* include a `time` variable, and ideally a `time_bnds` variable. If no `time_bnds` variable is given, it will be inferred from the time dimension under the assumption that the `time` values represent the centre of the intervals.

Continuing the previous 1 degree resolution example:

```julia
# The wind speed is taken from the "wind_speed" variable in the dataset, linearly interpolated between time points, treated as a point observation and indexed by the simulation time. The wind speed data should span the simulation time and have shape (360, 180, ntime).
forcing[:wind_speed] = DataForcing("demo_windspeed_dataset.nc", "wind_speed", Linear(), Point(), RealTime())

# The precipitation is taken from the "pr" variable in the dataset, uses the nearest value in time, treated as a summation over the interval and indexed by the simulation time. The precipitation data should span the simulation time and have shape (360, 180, ntime).
forcing[:precipitation] = DataForcing("demo_precipitation_dataset.nc", "pr", Nearest(), Sum(), RealTime())

# Set the harvest rate to be a seasonal forcing. Has shape (360, 180, 12) i.e. monthly values with the year 1950.
forcing[:harvest_rate] = DataForcing("seasonal_harvest_rates.nc", "harvest_rate", Previous(), Mean(), CyclicTime(DateTime(1950, 1, 1), Period(Year(1))))

# Set canopy heights to be PFT specific and seasonal, using the mapping from the parameters. This data has shape (360, 180, M, ntime), with the M axis used for the surface types. [:, :, 1, t] for EGBL, [:, :, 2, t] for C3 grass.
forcing[:canopy_heights] = DataForcing("demo_canopy_heights.nc", "canopy_height", Linear(), Point(), CyclicTime(DateTime(2000, 1, 1), Period(Year(1))), param_mapping)
```

#### Function Forcing

When specifying a `FunctionForcing`, the dataset and variable name arguments are replaced with a function argument. The function is called with a specific signature, depending on whether the forcing is surface specific or not:

```
# For surface agnostic forcing
function forcing_fn(x, y, t)
    ...
    return <scalar>
end

# For surface specific forcing
function forcing_fn(x, y, t, surface::SurfaceClass)
    ...
    return <scalar>
end
```

This also means that the surface specific forcing does not require the `param_mapping` argument, but it does require a function definition for each surface that will require that forcing. 

```julia
function herbivory_fraction(x, y, t, surface::EvergreenBroadleaf)
    ...
    return <scalar>
end

function herbivory_fraction(x, y, t, surface::C3Grass)
    ...
    return <scalar>
end
```

That doesn't necessarily mean that there is a separate method for every surface type- it is possible to use parent or Union types to provide methods for all child types e.g.

```
function herbivory_fraction(x, y, t, surface::Union{EvergreenBroadleaf, C3Grass})
    ...
    return <scalar>
end
```

#### Upgrading a Parameter to a Forcing

It is always possible to *upgrade* a parameter to a forcing. Any parameter required by the model can also be supplied by a forcing, which will "upgrade" it to a time series. However, the reverse is not true- a required forcing cannot be downgraded to a parameter, if a science implementation has requested it.

### Output

The model output is comprised of 2 concepts: `Sources` and `Streams`. The sources specify what the output data is, the streams define where the data goes.

#### Sources

Any piece of data referenceable within the model forcing, state or derived data is a valid target for a data source. Parameters are not included as they are constant in time, and should be trivially retrievable by the user in pre or post processing. A `Source` is defined by:

* `target`: The target variable to source the data from.
* `stream`: The stream to write the variable to.
* `method`: The processing method to apply to the data. Options are:
    - Mean
    - Min
    - Max
    - Sum
    - Point
* `name`: The NetCDF variable name to use. Defaults to `target` if not specified.
* `attrs`: Any other NetCDF variable attributes to apply.

It is possible to provide a vector of variables as a `target` to simplify the `Source` specification. Note that if the same variable is to be written to multiple streams, it must be done with separate `Source` definitions. This was a design decision made to improve clarity and simplify internal handling.

#### Streams

Streams represent NetCDF files that are to be written to. Any number of sources can be directed to a single stream, with the only rule being that two sources with the same `name` cannot be directed to the same stream. A `Stream` is defined by:

* `name`: The name of the stream. Corresponds to the `stream` entry in the `Source` definition.
* `frequency`: The frequency of writing to the file. Must be a `Period` which is a multiple of the timestep.
* `file_name`: The name of the NetCDF file to write. Defaults to "<name>.nc".
* `attrs`: Any other NetCDF attributes to apply.
