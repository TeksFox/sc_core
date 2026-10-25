require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/abilities.lua"

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

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end

  parameters.upgrade = config.upgrade

  setupAbility(config, parameters, "primary")
  setupAbility(config, parameters, "alt")

  -- elemental type and config (for alt ability)
  local elementalType = configParameter("elementalType", "physical")
  replacePatternInData(config, nil, "<elementalType>", elementalType)
  if config.altAbility and config.altAbility.elementalConfig then
    util.mergeTable(config.altAbility, config.altAbility.elementalConfig[elementalType])
  end

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

  -- palette swaps
  config.paletteSwaps = ""
  if config.palette then
    local palette = root.assetJson(util.absolutePath(directory, config.palette))
    local selectedSwaps = palette.swaps[configParameter("colorIndex", 1)]
    for k, v in pairs(selectedSwaps) do
      config.paletteSwaps = string.format("%s?replace=%s=%s", config.paletteSwaps, k, v)
    end
  end
  if type(config.inventoryIcon) == "string" then
    config.inventoryIcon = config.inventoryIcon .. config.paletteSwaps
  else
    for i, drawable in ipairs(config.inventoryIcon) do
      if drawable.image then
        drawable.image = drawable.image .. config.paletteSwaps
      end
    end
  end

  -- gun offsets
  if config.baseOffset then
    construct(config, "animationCustom", "animatedParts", "parts", "middle", "properties")
    config.animationCustom.animatedParts.parts.middle.properties.offset = config.baseOffset
    if config.muzzleOffset then
      config.muzzleOffset = vec2.add(config.muzzleOffset, config.baseOffset)
    end
  end

  -- populate tooltip fields
  
  parameters.primaryAbility = configParameter(primaryAbility)
  config.tooltipFields = {}

  config.tooltipFields.ammoNameLabel = root.itemConfig(config.ammoType).config.shortdescription

  config.tooltipFields.handImage = "/interface/uiparts/handlabel.png:1"
  if config.twoHanded then
    config.tooltipFields.handImage = "/interface/uiparts/handlabel.png:2"
  end
  parameters.shortdescription = config.shortdescription .. " +1"
  config.tooltipFields.levelLabel = "Lv." .. configParameter("level", 1)
  config.tooltipFields.dpsLabel = (configParameter("primaryAbility").baseDps or 0) * configParameter("level", 1)
  config.tooltipFields.speedLabel = string.format("%.1f",1 / configParameter("primaryAbility").fireTime)
  config.tooltipFields.multLabel = configParameter("primaryAbility").projectileCount
  config.tooltipFields.ammoLabel = configParameter("ammoCount")
  config.tooltipFields.reloadLabel = configParameter("reloadTime")

  --config.tooltipFields.energyPerShotLabel = util.round((config.primaryAbility.energyUsage or 0) * (config.primaryAbility.fireTime or 1.0), 1)
  --
  local damagePerShot = ((configParameter("primaryAbility").baseDps or 0) * (configParameter("primaryAbility").fireTime or 1.0)) * configParameter("level", 1)

  config.tooltipFields.damagePerShotLabel = string.format("%.1f", damagePerShot)
  --

  config.tooltipFields.damageKindImage = "/interface/elements/" .. elementalType .. ".png"
  config.tooltipFields.dealerImage = "/interface/uiparts/icons/dealers/" .. config.dealer .. ".png"

  if config.primaryAbility then
    config.tooltipFields.primaryAbilityTitleLabel = "Primary:"
    config.tooltipFields.primaryAbilityLabel = config.primaryAbility.name or "unknown"
  end
  if config.altAbility then
    config.tooltipFields.altAbilityTitleLabel = "Special:"
    config.tooltipFields.altAbilityLabel = config.altAbility.name or "unknown"
  end

  -- set price
  -- TODO: should this be handled elsewhere?
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end
