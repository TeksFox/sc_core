require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/scripts/staticrandom.lua"
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
  parameters.module = parameters.module or {}

  local rarity = util.weightedRandom(root.assetJson("/configs/weapon/weaponmain.config").modulerarity)
  parameters.rarity = parameters.rarity or rarity[1] or "common"

  config.inventoryIcon = util.absolutePath(directory, config.inventoryIcon)

  if config.category == "butt" then
    parameters.type = config.category
    parameters.module.inaccuracy = util.randomInRange(config.inaccuracy) * rarity[2]
  end

  if config.category == "barrel" then
    parameters.type = config.category
    parameters.module.damage = util.randomInRange(config.damage) * rarity[2]
    parameters.module.inaccuracy = util.randomInRange(config.inaccuracy) * rarity[2]
  end

  if config.category == "optics" then
    parameters.type = config.category
    parameters.module.crit = util.randomInRange(config.crit) * rarity[2]
    parameters.module.critMult = util.randomInRange(config.critMult) * rarity[2]
    parameters.module.inaccuracy = util.randomInRange(config.inaccuracy) * rarity[2]
  end

  return config, parameters
end
