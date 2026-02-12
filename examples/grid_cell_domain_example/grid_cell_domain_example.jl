# Define the surface types

# Water tiles
lake = @WaterType Lake
river = @WaterType River

water_mapping = Dict(lake => 4,
                     river => 5)

# Urban tiles
residential = @UrbanType Residential
industrial = @UrbanType Industrial

urban_mapping = Dict(residential => 6,
                     industrial => 7)

# Ice tiles
fixed_ice = @IceType FixedIce
glacier = @IceType Glacier

ice_mapping = Dict(fixed_ice => 8,
                   glacier => 9)
