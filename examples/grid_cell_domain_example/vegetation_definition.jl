# Vegetated tiles
EGT = @PFT EvergreenTree phenology=evergreen
DS = @PFT DeciduousShrub phenology=deciduous
grass = @PFT Grass phenology=evergreen

# Contains a list of keywords arguments, that describe the
# physics parameters. Falls back to default if not specified.
RadiationParameters(EGT) = RadiationParameters()
PhotosynthesisParameters(EGT) = PhotosynthesisParameters()

PFT_mapping = Dict(EGT => 1,
                   DS => 2,
                   grass => 3)

