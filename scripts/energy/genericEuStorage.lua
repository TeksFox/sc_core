require "/scripts/energy/euCore.lua"

local euCore = euCore
local euConfig

function init()
    animationLights = config.getParameter("animationLights")
    euConfig = config.getParameter("euConfig", "")
    euCore.init(euConfig)
    
    animator.setPartTag("light", "battaryProgress", imageCompressor(0))
end

function update(dt)
    euCore.update(dt)

    -- Anime
    local euPercent = euCore.getCurrentEu() / euConfig.euStorage
    animator.setPartTag("light", "battaryProgress", imageCompressor(euPercent))
end

function imageCompressor(size)
    local rect = config.getParameter("animationParameters", {0, 0, 0, 0}).indicatorRect
    return string.format("?crop=%s;%s;%s;%s", rect[1], rect[2], rect[3], rect[4] * size)
end

function die()
    if storage.currentEu > 0 then
        local storedConfig = root.itemConfig(object.name()).config
        local energy = storage.currentEu / (1 * euConfig.euStorage)
        local color = ""

        if energy <= 0 then
            color = "020202"
        elseif energy > 0 and energy < 0.25 then
            color = "FF0000"
        elseif energy >= 0.25 and energy < 0.5 then
            color = "FF6A00"
        elseif energy >= 0.5 and energy < 0.75 then
            color = "FFD800"
        elseif energy >= 0.75 and energy < 0.99 then
            color = "4CFF00"
        elseif energy > 0.99 then
            color = "00FFFF"
        end
        storedConfig.euConfig.euFromBeggining = euCore.getCurrentEu()
        storedConfig.inventoryIcon = storedConfig.inventoryIcon .. "?replace;020202=" .. color .. ""
        storedConfig.description = description(storedConfig.description, color, energy)
        world.spawnItem(object.name(), object.position(), 1, storedConfig)
    else
        world.spawnItem(object.name(), object.position(), 1)
    end
end
function description(description, color, energy)
    local desc =
        description ..
        "\nThe battery is " ..
            "^#" ..
                color ..
                    ";" ..
                        math.floor(energy * 100) ..
                            "%^reset; charged,\n ^#" .. color .. ";" .. math.floor(storage.currentEu) .. " ^reset;energy units"
    return desc
end
