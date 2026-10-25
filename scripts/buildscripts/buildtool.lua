require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/versioningutils.lua"

require "/scripts/utils/itembuilderutils.lua"

function build(directory, config, parameters, level, seed)

    config.tooltipFields = {}


    config.tooltipFields.darabilityLabel = string.format("%s / %s", config.durability, config.durability)
    config.tooltipFields.blockRadiusLabel = string.format("%s / %s", config.primaryAbility.blockRadius, config.primaryAbility.altBlockRadius) 
    config.tooltipFields.tileDamageLabel = config.primaryAbility.tileDamage

    return config, parameters
end
