require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/versioningutils.lua"

require "/scripts/utils/itembuilderutils.lua"

function build(directory, config, parameters, level, seed)
    local iConf = root.assetJson("/items/itemConfigs.config")

    config.tooltipFields = {}

    local title = ""
    local param = ""
    local color = ""

    for k, v in pairs(config.moduleparameter) do
        local conf = root.assetJson("/configs/moduleStatName.config")[k]

        title = title .. string.format(fontColor(v) .. "%s:\n", conf.name)

        param = param .. string.format(fontColor(v) .. "%s\n", math(v, conf.type) .. (procentage(conf.percentage) or ""))
    end

    config.tooltipFields.parameterTitleLabel = title
    config.tooltipFields.parameterLabel = param

    return config, parameters
end
--
function fontColor(param)
    if abs(param) then
        return "^green;"
    else
        return "^red;"
    end
end

function math(v, type)
    if type == "float" then
        v = v * 100
    end
    local symbol = ""

    if abs(v) then
        symbol = "+"
    else
        symbol = ""
    end
    return symbol .. v
end

function procentage(d)
    if d then
        return "%"
    end
end

function abs(c)
    return c > 0
end
