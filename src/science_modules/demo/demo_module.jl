# A module demonstrating how to build a science module, using a very basic soil moisture model.
# Some fraction of the precipitation water seeps into the soil, dependent on the current fraction of saturation.
# The moisture sinks over time into the infinite aquifer below.

# The parent module for any implementations underneath this
"""
    DemoSoilMoistureModule
"""
abstract type DemoSoilMoistureModule <: ScienceModule end

"""
    required_parameters(mod::DemoSoilMoistureModule, surface::SurfaceClass)

Define the required parameters for a generic surface to activate this science module.
"""
function required_parameters(mod::DemoSoilMoistureModule, surface::SurfaceClass)
    content_at_saturation = DataDefinition(standard_name="volumetric_soil_moisture_content_at_saturation",
                                      units="kg m-3",
                                      shape=(:land),
                                      description="Maximum amount of water the soil can hold."
                                     )
    aquifer_drainage = DataDefinition(standard_name="aquifer_drainage",
                                           units="kg m-2 s-1",
                                           shape=(:land),
                                           description="Rate at which water drains into the aquifer beneath."
                                          )

    return Dict(:content_at_saturation => content_at_saturation, :aquifer_drainage => aquifer_drainage)
end

"""
    required_parameters(mod::DemoSoilMoistureModule, surface::Union{VegetatedSurface, UrbanSurface})

Define the required parameters specifically for the VegetatedSurface and UrbanSurface surface classes.
"""
function required_parameters(mod::DemoSoilMoistureModule, surface::Union{VegetatedSurface, UrbanSurface})
    # Possible to invoke the more generic version, if this implementation is specifically an extension of the generic
    parent_params = @invoke required_parameters(mod::DemoSoilMoistureModule, surface::SurfaceClass)

    water_usage = DataDefinition(standard_name="water_usage",
                                     units="kg m-2 s-1",
                                     shape=(:tile),
                                     description="Rate at which the water is drained for other usage."
                                    )

    return merge(Dict(:water_usage => water_usage), parent_params)
end

"""
    required_forcings(mod::DemonSoilMoistureModule, surface::SurfaceClass)

Define the forcings required to operate the DemoSoilMoistureModule for any SurfaceClass.
"""
function required_forcings(mod::DemoSoilMoistureModule, surface::SurfaceClass)

    rainfall = DataDefinition(standard_name="precip",
                                 units="kg m-2 s-1",
                                 shape=(),
                                 description="Precipitation rate",
                                )

    return Dict(:rainfall => rainfall)
end

"""
    state_variables(mod::DemoSoilMoistureModule, surface::SurfaceClass)

Define the state variables required for the DemoSoilMoistureModule for any SurfaceClass.
"""
function state_variables(mod::DemoSoilMoistureModule, surface::SurfaceClass)
    soil_moisture = DataDefinition(standard_name="soil_moisture_content_in_alayer",
                                   units="kg m-3",
                                   shape=(:tile, :soil),
                                   description="Volumetric soil moisture in a soil layer"
                                  )

    return Dict(:soil_moisture => soil_moisture)
end

"""
    dependent_variables(mod::DemoSoilMoistureModule, surface::SurfaceClass)

Define the dependent variables for the DemoSoilMoistureModule for any SurfaceClass.
"""
function dependent_variables(mod::DemoSoilMoistureModule, surface::SurfaceClass)
    # Just make this the current saturation fraction, although it's trivial to compute on the fly
    frac_of_saturation = DataDefinition(standard_name="frac_of_saturation",
                                        units="1",
                                        shape=(),
                                        description="Current fraction of saturation"
                                       )

    return Dict(:fraction_of_saturation => frac_of_saturation)
end
