struct SingleLayerSoilMoistureImplementation{T} <: DemoSoilMoistureModule
    layer_thickness::T
end

function define_dimensions(mod::SingleLayerSoilMoistureModule, surface::SurfaceClass, dims)
    add_dimension(:soil, 1, dims)
end


