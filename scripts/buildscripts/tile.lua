require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/versioningutils.lua"

function build(directory, config, parameters, level, seed, tooltipFields)
    local material = root.materialConfig(config.materialName).config
    config.tooltipFields = config.tooltipFields or {}
    config.tooltipFields.lightTransparentLabel = boolParameters(material.renderParameters.lightTransparent)
    config.tooltipFields.occludesBelowLabel = boolParameters(material.renderParameters.occludesBelow)
    config.tooltipFields.multiColoredLabel = boolParameters(material.renderParameters.multiColored)
    config.tooltipFields.largeImage = directory .. config.largeImage
    local mhealth = material.health or 1
    config.tooltipFields.healthLabel = "x" .. mhealth
    return config, parameters
end

function boolParameters(bool)
    if bool == true then
        return "^green;Yes"
    else
        return "^red;No"
    end
end
