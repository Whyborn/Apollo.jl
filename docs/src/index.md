# Apollo

Apollo.jl is a toy biosphere code I created to prove it's possible write climate models that aren't terrible to use.

## Glossary of Terms

### Surface Classes and Traits

The fundamental data structure that the model is built on are **Surface Classes**. These broadly classify the type of surface for the given computational unit. The surface classes available are **Vegetated** (i.e. PFT), **Water**, **Ice** and **Urban**. The surface classes are specialised by **Surface Tiles**, each of which define a set of **Traits** required for the parent class. The behaviour of a specific tile is defined based on its parent class and its traits, rather than the class itself. The surface tiles are not defined by the model- these are defined by the user in the simulation set up.

#### Surface Classes and Traits Implementation

The model defines the abstract type `SurfaceClass`, with the surface being defined as subclasses of `SurfaceClass`.

```julia
abstract type VegetatedSurface <: SurfaceClass end
abstract type WaterSurface <: SurfaceClass end
abstract type IceSurface <: SurfaceClass end
abstract type UrbanSurface <: SurfaceClass end
```

The traits are defined for each surface class by defining a parent type for the trait, and the options for the given trait. For example, for the vegetated surface, each tile must define the PFT's phenology:

```julia
abstract type Phenology end
struct Evergreen <: Phenology end
struct Deciduous <: Phenology end
```

When defining a new `VegetatedSurface` tile, the phenology of the new tile must be specified with:

```julia
struct ExampleVegetatedTile <: VegetatedSurface end
phenology(::Type{ExampleVegetatedTile}) = Evergreen()
```

### Domain

The **Domain** details the computational units which comprise the simulation. The domain contains vectors which describe the latitudes and longitudes for each grid cell in the domain, as well as the bounds of each cell. These vectors do *not* necessarily describe a grid- each `(lat, lon)` pair describes the centre of a single cell, and the vectors are always of the same length. The domain also describes the surface of each cell. This is stored by a trio of tuples:

1. A tuple of each of the surface tiles used in the simulation.
2. A tuple of integer vectors, stating which cells contain some fraction of the corresponding surface subclass.
3. A tuple of float vectors, stating the fraction of the cell occupied by the given surface subclass.

The domain description is consistent between spatial and site runs.

#### Domain Implementation

The domain is a concrete type, defined as follows:

```julia
struct Domain{T, N, M}
    mask::Array{Bool, M}            ! The mask representing which points are active. Must be the same shape as the land cover fraction array.
    lons::Vector{T}                 ! Vector of grid cell centre lons for cells active in the simulation. Size M, where M is the number of active grid cells.
    lats::Vector{T}                 ! Vector of grid cell centre lats for cells active in the simulation. Size M.
    lon_bnds::Matrix{T}             ! Lon bounds of each grid cell active in the simulation. Size (2, M)
    lat_bnds::Matrix{T}             ! Lon bounds of each grid cell active in the simulation. Size (2, M)
    tiles::NTuple{N, SurfaceClass}  ! Tuple of tiles active in the simulation. N is the number of tiles used.
    indices::NTuple{N, Vector{Int}} ! Tuple of index vectors, indicating which grid cells contain the corresponding tile.
    fractions::NTuple{N, Vector{T}} ! Tuple of grid cell fractions, denoting what fraction each tile occupies for the specific grid cell. Vector lengths are the same as those in indices.
end
```

This provides a uniform description for both gridded and site domain runs. The domain can be defined in multiple ways. For gridded simulations, the most common method is to pass a 3D land cover `CommonDataModel` dataset `(cover_type, lon, lat)` and a mapping from the land cover classes to the defined tiles. The land cover dataset must be CF compliant i.e. use `land_area_fraction` for the area occupied by each tile, `lon` for the longitudes and `lat` for the latitudes. The `lon_bnds` and `lat_bnds` are optional- if not detected, they will be inferred from the existing coordinates, assuming equal spacing. The mapping is a dictionary which links the defined tiles to cover types in the land cover array. By default, all points with a non-zero land area fraction are included, but a mask can be passed as an optional argument, which can be used to switch off points as desired. This applies for gridded or site simulations.

```julia
mapping = Dict(
    EvergreenBroadleaf() => 1,
    DeciduousBroadleaf() => (2, 3),
    C3Grass() => 4,
    StaticIce() => 6
    )

domain = Domain(land_cover_dataset, mapping)
```

Alternatively, the longitudes, latitudes and land cover map can be provided explicitly.

```julia
domain = Domain(lons, lats, land_cover_array::Array{T, 3}, mapping)
```

This would treat the first page of the array (i.e. `land_cover_dataset["land_cover_fraction"][1, :, :]`) as `EvergreenBroadleaf`, 2nd and 3rd pages as `DeciduousBroadleaf` (with summed area fractions), 4th as `C3Grass` and 6th as `StaticIce`. Note that this means the 5th page of the array is ignored. The total area for a grid cell is *not* normalised to 1 by default, but the keyword argument `normalise` can be set to `true` to scale the areas such that the total for a grid cell is 1.

The process is similar for site simulations, except that the land cover dataset is now a 2D array of `(cover_type, sites)`.

### Model Inputs

There are two classes of inputs to the model: **Parameters** and **Forcing**. Parameters are values that remain the same throughout the simulation. Parameters can be either **SpatialParameters**, defined based on some input array or **TileParameters**, defined based on the current tile.

Forcings have both a time and source definition. The time can be either **TrueTime**, which uses the real model time, or **CyclicTime**, which repeated forcing from a specified time period (this includes seasonal forcing). The source can either **FunctionalForcing**, which takes the forcing from a user-defined function, or **FromFileForcing**, which takes forcing from any `CommonDataModel` file.

#### Model Inputs Implementation

##### Parameters

Each parameter must be specified as either a `SpatialParameter` or a `TileParameter` in the dictionary of parameters used by the model. A `SpatialParameter` takes an array or `CommonDataModel` dataset, with associated variable name as input. The dimensions must be compatible with the size of the domain i.e. either on the same grid as the passed land cover dataset, or have length equal to the number of sites used in a site simulation.

```julia
params = Dict()
params[:soil_moisture_content_at_wilting] = SpatialParameter(smc_wilt_array)     # smc_wilt_array is some lon x lat array of soil moisture content at wilting data
params[:soil_moisture_content_at_saturation] = SpatialParameter(soil_parameter_dataset, "smc_saturation")    # soil_parameter_dataset is a CommonDataModel dataset, referring to the "smc_saturation" variable.
```

If the parameter is a `TileParameter`, then there must be a function for the given parameter with signature that matches each tile in the simulation. The call signature of the function is `<parameter_name>(tile::SurfaceClass)`. This means the configuration must define functions for each of these parameters, for each of the tiles that require that parameter. Note that that does not mean there have to be the same number of functions as tiles, just at least one with signature that matches each tile.

```julia
params[:carbon_nitrogen_ratio] = TileParameter()
carbon_nitrogen_ratio(tile::VegetatedSurface) = value_a         ! Any vegetated surface will get this value for carbon_nitrogen_ratio, unless a more specific definition is given
carbon_nitrogen_ratio(tile::EvergreenBroadleaf) = value_b       ! This is a more specific definition for EvergreenBroadleaf, so that tile will take this value
carbon_nitrogen_ratio(tile::Union{C3Grass, C4Grass}) = value_c  ! The grass types will get this value, as it is more specific.
```

In this instance, the `EvergreenBroadleaf` tiles will get `value_b`, `C3Grass` and `C4Grass` will get `value_c` and any other vegetated surfaces will get `value_a`.

The [module implementations](#module-implementations) specify which parameters are required for a given module.

##### Forcing

Each forcing must provide a time period and a source. The possible time period definitions are `TrueTime()` or `CyclicTime(start_time::DateTime, end_time::DateTime)`. Note that the `start_time` will be aligned with the beginning of the simulation, and the `end_time` is used to construct a `TimePeriod`.

```julia
seasonal_forcing = CyclicTime(DateTime(2000, 1, 1), DateTime(2001, 1, 1))       ! A seasonal forcing, with 1 year period
preindustrial_forcing = CyclicTime(DateTime(1900, 1, 1), DateTime(1910, 1, 1))  ! A pre-industrial forcing with 10 year period
```

It is important to be aware of the effect of the calendar and leap years on the interval. The `CyclicTime` effectively sets the time for the specific forcing to be `start_time + mod(sim_time - sim_start_time, end_time - start_time)`. This may cause date offsets if leap years don't match up between the periodic interval and the real time.

To specify the forcing coming from an external source, specify the `CommonDataModel` dataset (this may be a multifile dataset) and the target variable in the dataset to use, along with the time method to use. The target time must fall within the bounds of the `time` axis of the dataset. When specifying an external forcing, the interpolation method between snapshots must be specified. The possible options are:

1. `Linear()`: Linearly interpolate between neighbouring snapshots.
2. `Nearest()`: Nearest snapshot to the target time.
3. `Previous()`: Take the most recent snapshot.

The forcing must be on the same grid as the land area fraction dataset. Some examples of defining external forcing are:

```julia
forcing[:leaf_area_index] = FromFileForcing(leaf_area_index_ds, "leaf_area_index", seasonal_forcing, Linear())   ! Yearly seasonal forcing, with interpolation between time snapshots
forcing[:precipitation] = FromFileForcing(precipitation_ds, "precipitation", preindustrial_forcing, Nearest())   ! 10 year periodic forcing, taking the nearest snapshot as reference
forcing[:co2] = FromFileForcing(co2_ds, "atmospheric_co2", RealTime(), Previous())                               ! Real time forcing, taking the data from the previous snapshot
```

Alternatively, for idealised simulations, functional forcing can be supplied for forcing. The signature of the function called to compute forcing is `get_forcing(tile::SurfaceClass, time, lon, lat)`, where `time` is the time returned from the time period definition i.e. the true sim time for `TrueTim)` forcing, or the modulo time for `CyclicTime`, `lon` and `lat` are the coordinates from the `Domain`. The `tile` argument allows different forcing for different tiles.

```julia
function lw_rad(tile::SurfaceClass, t, x, y)
    sin(hour(t) * 2π / 24 + x * π / 180)
end

function lw_rad(tile::IceSurface, t, x, y)
    2 * sin(hour(t) * 2π / 24)
end

forcing[:longwave_radiation] = FunctionalForcing(lw_rad, RealTime())    ! One forcing for ice surfaces, another for all other surfaces.
```

### Model State

The **Model State** is comprised of two types of variables: **State Variables**
The model is designed to be configurable by users from the ground up. The model utilises the classic surface class discretization model utilised in many land models. Specifically, it follows the approach of the Community Land Model, in that there are a small number of distinct overarching surface classes which are defined by the model: **Plant Functional Types (PFTs)**, **Water**, **Urban** and **Ice**. Each of these surface classes encompasses some number of sub-classes, which are created by the user. Each top level class has a fixed set of **traits** that must be specified when the sub-class is declared.

```
EGBL = @PFT EvergreenBroadleaf phenology=evergreen
```

This defines a new type `EvergreenBroadleaf`, with the trait `phenology(::EvergreenBroadleaf) = Evergreen()`. Note that the macro returns the type itself, rather than an instance of the type. The new class is a sub-type of the top level class, so `EGBL == EvergreenBroadleaf` and `EGBL <: PFT`.

Behaviour is determined by the top level surface class, *and the traits assigned to the respective sub-classes*, rather than the subtypes themselves. For example, when computing the growing cycle for PFTs, instead of asking "Is the current PFT one of X, Y or Z?", the code asks "Is this PFT deciduous?", and then calls the appropriate method.

Parameters are determined by the sub-class. Each science module may have a set of parameters required for the module to function. Each sub-type must specify the parameters the module should use for the sub-type, by dispatching on the sub-type.

```
RadiationParameters(::EvergreenBroadleaf) = RadiationParameters(; kwargs...)
```

The `kwargs` of `RadiationParameters` are the parameters required for the science module. Any parameters not specified will be given a default for the top level class, which are typically values that will allow the model to run, but typically it's not possible to have default parameter values which are accurate for every sub-class.

## Model State

There are 4 classifications of data which control the model. These terms are referred to throughout the documentation.

1. **Parameters**: Data that remains fixed in time. This can be specified per class, sub-class or trait, or spatially i.e. `p(t)=p(C)`, where `C` is the simulation configuration. Note that this means there are situations where parameters on a tile may change, when the characterization of that tile changes e.g. due to vegetation dynamics.
2. **Forcing**: Data that varies in time i.e. `F(t)=F(t,C)`. This can be a true time series e.g. weather forcing or periodic e.g. seasonal.
3. **State variables**: These are specifically variables that have rates of change associated with them i.e. `U(t+1) = U(t) + dU(t) * Δt`.
4. **Dependent variables**: These are variables which are inferred from the current state and parameters i.e. `V(t)=V(U(t), p)`.

## Model Science

The model science is designed to be extendable. The physics is separate into *modules*, each representing the *what* regarding an aspect of the science. Each *module* is the parent of one or more *implementations*, which actually describe the *how* for the aspect of science. The module specifies what methods and variables each of the implementations must define- it effectively makes a promise that these are the things that will be available for other modules to use. This means the module must define:

* The minimum set of state and dependent variables that must be defined for any implementation of the module.
* The minimum set of methods that must be defined for any implementation of the module.

The respective implementations, in addition to describing rates of change of state variables and computing dependent variables, describe how the promise made by the module is fulfilled. The implementations must define:

* Any additional state or dependent variables defined by the implementation.
* Concrete definitions for each of the methods specified by the parent module.


### Setting required state variables

When initialising a simulation, the function `create_state_variables(phys_mod, surface_type, sim_conf::SimConfig)` is called for each physics module and surface type that is active in the simulation. The generic specific call signature of `create_state_variables(::PhysicsModule, ::SurfaceType, ::SimConfig)` will throw an error, so every module must define a more specific signature than this. For example, there may be three existing implementations of soil hydraulics which all use the same set of state variables- these may rely on the module level implementation of `create_state_variables` i.e. `create_state_variables(::SoilHydraulicsModule, ::SimConfig). But a new implementation may add new state variables, which would require a more specific signature like `create_state_variables(::NewSoilHydraulicsModule, ::SimConfig), which would return the extended set of variables. The return type must be a `ComponentArray`.

### Setting required parameters

The required parameters specify 
Parameters can be set in one of 3 ways:

1. By association with a top level class e.g. `module_parameters(::PhysicsModule, ::PFT)`
2. By association with a given trait e.g. `module_parameters(::PhysicsModule, ::Evergreen)`
3. By association with a sub-class e.g. `module_parameters(::PhysicsModule, ::C3Grass)`.

Association via top level class or trait should be done by the developer in the source code, while association via sub-class should be done by the user in a configuration.
For example, the soil hydraulics module may require the state variable `volume_fraction_of_condensed_water_in_soil`, the spatial parameters `volume_fraction_of_condensed_water_in_soil_at_critical_point` and `volume_fraction_of_condensed_water_at_field_capacity` and the per-PFT parameter `volume_fraction_of_condensed_water_in_soil_at_wilting_point`. It must define the method `volume_fraction_condensed_water_at_depth(::SoilHydraulicsModel, depth)`. It does not require any other modules to be active to operate, so it has no dependencies. However, the ground water module may require the soil hydraulics module to be active to be meaningful, so soil hydraulics would be a dependency for the ground water module.

The

## Domain Definition

A domain can either be a gridded domain, or a domain defined by a set of sites. A gridded domain requires latitude and longitude coordinates, with the bounds being optional, with a land cover map and optional land mask. The land cover map should be an array with dimensions `land_cover_class, lon, lat`, which describes the fraction of the `(lon, lat)` occupied by the given land cover class. If a landmask is supplied, the domain will be restricted to that landmask. Alternatively, supply a `Dataset` containing `lon`, `lat` and a `land_cover_fraction`. A surface sub-class is assigned to a specific land cover class through a dictionary mapping.

```
EGBL = @PFT EvergreenBroadleaf phenology=evergreen
C3G = @PFT C3Grass phenology=deciduous
lake = @WaterClass Lake
fixed_ice = @IceClass FixedIce

mapping = Dict( EGBL => (1, 2),
                C3G => 3,
                lake => 4,
                fixed_ice => 5
The respective implementations, in addition to describing rates of change of state variables and computing dependent variables, describe how the promise made by the module is fulfilled. The implementations must define:

* Any additional state or dependent variables defined by the implementation.
* Concrete definitions for each of the methods specified by the parent module.


### Setting required state variables

When initialising a simulation, the function `create_state_variables(phys_mod, surface_type, sim_conf::SimConfig)` is called for each physics module and surface type that is active in the simulation. The generic specific call signature of `create_state_variables(::PhysicsModule, ::SurfaceType, ::SimConfig)` will throw an error, so every module must define a more specific signature than this. For example, there may be three existing implementations of soil hydraulics which all use the same set of state variables- these may rely on the module level implementation of `create_state_variables` i.e. `create_state_variables(::SoilHydraulicsModule, ::SimConfig). But a new implementation may add new state variables, which would require a more specific signature like `create_state_variables(::NewSoilHydraulicsModule, ::SimConfig), which would return the extended set of variables. The return type must be a `ComponentArray`.

### Setting required parameters

The required parameters specify 
Parameters can be set in one of 3 ways:

1. By association with a top level class e.g. `module_parameters(::PhysicsModule, ::PFT)`
2. By association with a given trait e.g. `module_parameters(::PhysicsModule, ::Evergreen)`
3. By association with a sub-class e.g. `module_parameters(::PhysicsModule, ::C3Grass)`.

Association via top level class or trait should be done by the developer in the source code, while association via sub-class should be done by the user in a configuration.
