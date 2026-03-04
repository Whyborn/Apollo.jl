@VegetatedSurface EvergreenBroadleaf phenology=evergreen
@VegetatedSurface DeciduousNeedleleaf phenology=deciduous
@VegetatedSurface C3Grass phenology=deciduous

@WaterSurface Lake

@UrbanSurface City

@IceSurface FixedIce

mapping = Dict(EvergreenBroadleaf() => 1,
               DeciduousNeedleleaf() => 2,
               C3Grass() => [6, 7],
               Lake() => 16,
               City() => 15,
               FixedIce() => 17
              )
