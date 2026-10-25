require "/scripts/util.lua"
require "/scripts/interp.lua"

require "/scripts/utils/util_object.lua"

oldInit = init
oldUninit = uninit
oldUpdate = update
oldDie = die

function init(...)
    oldInit()
    storage.imageVariant = storage.imageVariant or math.random(1, 5)
    active = false
    storage.drill = storage.drill or nil

    storage.parameters = storage.parameters or {}
    createDeposit(world.type())
    message.setHandler(
        "placeDrill",
        function(_, _, name)
            sb.logInfo("%s", name)
            storage.drill = name
            active = true
            world.breakObject(entity.id(), true)
        end
    )
end

function createDeposit(type)
    local biomelayer = config.getParameter("biomelayer", "surface")
    local data = root.assetJson("/configs/mineraldeposit/main.config")
    local depositData = root.assetJson("/configs/mineraldeposit/" .. type .. ".config")
    local deposit = util.weightedRandom(depositData[biomelayer])
    local rarity = util.weightedRandom(data.weight)
    local weight = math.floor((math.random(data.counts[biomelayer][1], data.counts[biomelayer][2])) * rarity[2])

    storage.parameters = {
        depositRarity = rarity[1],
        items = deposit.items,
        color = deposit.color,
        counts = {weight, weight},
        harvestLevel = config.getParameter("harvestLevel", 1)
    }

    objectUtils.setColor("body", "color", deposit.color)
    object.setConfigParameter("objectRes", storage.parameters)
end

function die()
end

function uninit()
    if active then

        world.placeObject(storage.drill, object.position(), object.direction(), storage.parameters)
    end
end
