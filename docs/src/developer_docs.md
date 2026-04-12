# Information for Developers

The setup process for the model is built on two data structures: `Domain` and `DataDefinition`.

## Domain

The `Domain` describes the domain on which the simulation operates. The `Domain` contains:

* `sim_map`: A `DomainMap` which describes the *location* of the simulation. The `DomainMap` can be either a `GriddedMap` for gridded simulations, or a `SiteMap` for site simulations. These contains the same components, with the meaning of the components varying slightly between implementations:
    * `mask`: Which points are active. For the `GriddedMap`, this is a matrix, typically used to differentiate land/ocean, while for `SiteMap`, this is a vector, used for switching particular sites on/off.
    * `x`, `y`: The coordinates of the points, typically longitudes and latitudes. For a `GriddedMap`, these describe the domain axes, while for `SiteMap`, these are pairs describing the location of each site.
    * `x_bnds`, `y_bnds`: The bounds the points. Similar to `x` and `y`, for a `GriddedMap`, these are axes, while for `SiteMap`, these are pairs.
* `tile_map`: A 'TileMap` which describes where the respective tiles exist on the simulation domain. The `TileMap` contains:
    * `tiles`: A tuple of surface classes, which describe which surface classes are active in the current simulation.
    * `indices`: A tuple of index vectors, representing the locations in the `sim_map` mask for the respective surface classes in the `tiles` tuple.
    * `fractions`: A tuple of fractions, representing the fraction of the given grid cell assigned to the specific land fraction.

## Dimensions

When declaring data to be used in the model, it is required to define the shape of the data through `Dimension`s. The `Dimension`s are used to initialise data shapes and to assist mapping between data defined on different spaces. All dimensions are defined as subtypes of the parent `Dimension` class. There are two dimensions that are always defined:

* `Land`: Data is defined on a vector of land points i.e. the number of `true` values in the `Domain.sim_map.mask`. All data defined on `Land` is accessed via the `land` attribute on the data arrays e.g. `parameters.land.<internal_name>`.
* `Tile`: Data is defined on vectors representing the tiles i.e. the length of the `indices` arrays for each surface type. The data defined on `Tile` is accessed via the associated surface name on the data arrays e.g. `parameters.<surface_name>.<internal_name>`.
* `None`: Data that does not have any spatial dependence. The data defined on `Homogenous` is accessed via the `homogeneous` attribute e.g. `parameters.homogeneous.<internal_name>`.

Every piece of data must have a first dimension of either `Land`, `Tile` or `Homogeneous`. Additional dimensions are defined by:

```julia
type NewDimension <: Dimension
    size::Int
end

# Determine how to compute the size of the new dimension, using the sim `Domain`.
function NewDimension(domain)
    # Use the information attached to the domain to compute the size of the new dimension.
    ...
    return NewDimension(new_size)
end
```

## Data Definitions

Every piece of data in the model is defined by a `DataDefinition`. Each `DataDefinition` defines both the way the data appears in the model, and the metadata associated with the data when it is written to disk. The components of a `DataDefinition` are:

* `internal_name`: A `Symbol` which defines how the data is accessed in the internal data arrays. Corresponds to the `<internal_name>` mentioned in the (#Dimensions) section.
* `standard_name`: A `String` which is used as the associated NetCDF variable attribute. Should be the CF standard name where possible.
* `long_name`: A `String` which is used as the associated NetCDF variable attribute. This is not required, defaults to `nothing`, in which case the attribute is not included.
* `units`: A `String`, which is used as the associated NetCDF variable attribute.
* `cell_methods`: A `String` which is used as the associated NetCDF variable attribute. This is not required, defaults to `nothing`, in which case the attribute is not included.
* `shape`: A `Tuple` of `Dimension`s as described the (#Dimensions) section. Must have `Land`, `Tile` or `Homogeneous` as the leading dimension (note this is the type itself, not an instance of the type).
* `description`: A `String` description of the data, used as the associated NetCDF variable attribute.
* `other_attrs`: Any other NetCDF variable attributes to include.

The `DataDefinition` is used in combination with either an `AbstractParameter` or `AbstractForcing` which describes where the data will be sourced from. 

## 
