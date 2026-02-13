# Apollo

Apollo.jl is a toy biosphere code I created to prove it's possible write climate models that aren't terrible to use.

## Usage

## Surface Classes

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

## Physics Definition

The model physics is designed to be interoperable as much as possible. The physics is separate into a series of modules e.g. radiation, soil hydraulics and thermodynamics. The top level module doesn't define any physics- only specifies *what* the module does, rather than how it does it. Each module defines:

* The minimum set of state variables required for the module.
* The minimum set of per-PFT and spatial parameters required for the module.
* The minimum set of methods that must be defined for any realisation of the module.
* The dependencies of the module.

### Setting required state variables

When initialising a simulation, the function `create_state_variables(phys_mod, surface_type, sim_conf::SimConfig)` is called for each physics module and surface type that is active in the simulation. The generic specific call signature of `create_state_variables(::PhysicsModule, ::SurfaceType, ::SimConfig)` will throw an error, so every module must define a more specific signature than this. For example, there may be three existing implementations of soil hydraulics which all use the same set of state variables- these may rely on the module level implementation of `create_state_variables` i.e. `create_state_variables(::SoilHydraulicsModule, ::SimConfig). But a new implementation may add new state variables, which would require a more specific signature like `create_state_variables(::NewSoilHydraulicsModule, ::SimConfig), which would return the extended set of variables. The return type must be a `ComponentArray`.

### Setting required parameters

Parameters can be set in one of 3 ways:

1. By association with a top level class e.g. `module_parameters(::PhysicsModule, ::PFT)`
2. By association with a given trait e.g. `module_parameters(::PhysicsModule, ::Evergreen)`
3. By association with a concrete class e.g. `module_parameters(::PhysicsModule, ::C3Grass)`.


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
                )
```

In this instance, land cover indices 1 and 2 will be mapped to the `EvergreenBroadleaf` class, 3 to `C3Grass`, 4 to `Lake` and 5 to `FixedIce`. Note that not every land cover index needs to be mapped to a class- any not mapped will be ignored.

```
domain = grid_cell_domain(lons, lats, fractions, mapping; normalise=false)
```

Alternatively, a `CommonDataModel` `Dataset` may be supplied, with attributes `lon`, `lat` and `land_area_fraction` as the input dataset, along with the mapping.

```
domain = grid_cell_domain(ds::Dataset, mapping; normalise=false)
```


