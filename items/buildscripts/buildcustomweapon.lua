require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/abilities.lua"

require "/scripts/sf_utils.lua"

function build(directory, config, parameters, level, seed)
    local configParameter = function(keyName, defaultValue)
        if parameters[keyName] ~= nil then
            return parameters[keyName]
        elseif config[keyName] ~= nil then
            return config[keyName]
        else
            return defaultValue
        end
    end
    local builderConfig = root.assetJson("/configs/weapon/weaponmain.config")
    local setup = config.setup or parameters.setup or true
    parameters.customweapon = true
    parameters.rarity = parameters.rarity or config.rarity or "common"

    parameters.pid = parameters.pid or math.random(0, 999999999)

    if level and not configParameter("fixedLevel", true) then
        parameters.level = level
    end

    setupAbility(config, parameters, "primary")
    setupAbility(config, parameters, "alt")

    parameters.primaryAbility = parameters.primaryAbility or {}

    parameters.primaryAbility.fireTime = parameters.primaryAbility.fireTime or config.primaryAbility.fireTime
    parameters.primaryAbility.baseDps = parameters.primaryAbility.baseDps or config.primaryAbility.baseDps
    parameters.primaryAbility.crit = parameters.primaryAbility.crit or config.primaryAbility.crit or 0.12
    parameters.primaryAbility.critMult = parameters.primaryAbility.critMult or config.primaryAbility.critMult or 1.5

    -- elemental type and config (for alt ability)
    local elementalType = configParameter("elementalType", "physical")
    replacePatternInData(config, nil, "<elementalType>", elementalType)
    if config.altAbility and config.altAbility.elementalConfig then
        util.mergeTable(config.altAbility, config.altAbility.elementalConfig[elementalType])
    end

    -- calculate damage level multiplier
    config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

    config.animationParts = config.animationParts or {}
    parameters.modules = parameters.modules or config.modules

    for _, item in pairs(parameters.modules) do
        local iConf = root.itemConfig(item.name)
        config.animationParts[item.parameters.type] = util.absolutePath(iConf.directory, iConf.config.inventoryIcon)
    end

    -- palette swaps
    config.paletteSwaps = ""
    if config.palette then
        local palette = root.assetJson(util.absolutePath(directory, config.palette))
        local selectedSwaps = palette.swaps[configParameter("colorIndex", 1)]
        for k, v in pairs(selectedSwaps) do
            config.paletteSwaps = string.format("%s?replace=%s=%s", config.paletteSwaps, k, v)
        end
        parameters.setup = false
    end
    -- if type(config.inventoryIcon) == "string" then
    --     config.inventoryIcon = config.inventoryIcon .. config.paletteSwaps
    -- else
    --     for i, drawable in ipairs(config.inventoryIcon) do
    --         if drawable.image then
    --             drawable.image = drawable.image .. config.paletteSwaps
    --         end
    --     end
    -- end

    -- gun offsets
    local partImagePositions = {}
    if config.animationParts then
        construct(config, "animationCustom", "animatedParts", "parts")
        local imageOffset = {0, 0}
        local gunPartOffset = {0, 0}
        for _, part in ipairs(parameters.modules) do
            local imageSize = root.imageSize(config.animationParts[part.parameters.type])
            construct(config.animationCustom.animatedParts.parts, part.parameters.type, "properties")
            if checkPart(part.parameters.type) then
                imageOffset = vec2.add(imageOffset, {imageSize[1] / 2, 0})
                config.animationCustom.animatedParts.parts[part.parameters.type].properties.offset = {config.baseOffset[1] + imageOffset[1] / 8, config.baseOffset[2]}
                partImagePositions[part.parameters.type] = copy(imageOffset)
                imageOffset = vec2.add(imageOffset, {imageSize[1] / 2, 0})
            else
                local param = config.customParts[part.parameters.type]
                local pos = config.animationCustom.animatedParts.parts[param.part].properties.offset
                local posX = (imageSize[1] / 2) / 8
                local posY = (imageSize[2] / 2) / 8

                config.animationCustom.animatedParts.parts[part.parameters.type].properties.offset = {pos[1] + posX + param.x, pos[2] + sf_util.invert(posY, param.inverted) + param.y}
            end
        end
        config.muzzleOffset = vec2.add(config.baseOffset, vec2.add(config.muzzleOffset or {0, 0}, vec2.div(imageOffset, 8)))
    end

    if not config.inventoryIcon and config.animationParts then
        config.inventoryIcon = jarray()
        local parts = parameters.modules or config.modules
        for _, partName in pairs(parts) do
            local drawable = {
                image = config.animationParts[partName.parameters.type] .. config.paletteSwaps,
                position = {
                    config.animationCustom.animatedParts.parts[partName.parameters.type].properties.offset[1] * 8,
                    config.animationCustom.animatedParts.parts[partName.parameters.type].properties.offset[2] * 8
                }
            }
            table.insert(config.inventoryIcon, drawable)
        end
    end

    -- populate tooltip fields
    if config.tooltipKind ~= "base" then
        config.tooltipFields = {}
        config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
        config.tooltipFields.dpsLabel = util.round((config.primaryAbility.baseDps or 0) * config.damageLevelMultiplier, 1)
        config.tooltipFields.speedLabel = util.round(1 / (config.primaryAbility.fireTime or 1.0), 1)
        config.tooltipFields.damagePerShotLabel = util.round((config.primaryAbility.baseDps or 0) * (config.primaryAbility.fireTime or 1.0) * config.damageLevelMultiplier, 1)
        config.tooltipFields.energyPerShotLabel = util.round((config.primaryAbility.energyUsage or 0) * (config.primaryAbility.fireTime or 1.0), 1)
        config.tooltipFields.crit = string.format("%.2f %%", parameters.primaryAbility.crit * 100)
        config.tooltipFields.critMult = string.format("%.2f %%", parameters.primaryAbility.critMult * 100)

        if elementalType ~= "physical" then
            config.tooltipFields.damageKindImage = "/interface/elements/" .. elementalType .. ".png"
        end
        if config.primaryAbility then
            config.tooltipFields.primaryAbilityTitleLabel = "Primary:"
            config.tooltipFields.primaryAbilityLabel = config.primaryAbility.name or "unknown"
        end
        if config.altAbility then
            config.tooltipFields.altAbilityTitleLabel = "Special:"
            config.tooltipFields.altAbilityLabel = config.altAbility.name or "unknown"
        end
    end

    -- set price
    -- TODO: should this be handled elsewhere?
    config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

    return config, parameters
end

function checkPart(name)
    local ignoreParts = {"optics", "magazine", "addon"}
    for _, i in pairs(ignoreParts) do
        if name == i then
            return false
        end
    end
    return true
    -- body
end
