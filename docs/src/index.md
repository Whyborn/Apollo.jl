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
domain = grid_cell_domain(
