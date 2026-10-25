require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/utils/util_object.lua"

function init()
    harvestLevel = config.getParameter("harvestLevel", 1)
    consumeEnergy = config.getParameter("consumeEnergy", 5)
    miningLevel = config.getParameter("miningLevel", 1)
    maxEnergy = config.getParameter("maxenergy", 1000)
    barSize = config.getParameter("barSize")

    storage.addedTimer = storage.addedTimer or 1
    storage.active = storage.active or false
    storage.extracted = storage.extracted or 0
    storage.energy = storage.energy or 0
    storage.resources = storage.resources or config.getParameter("counts", {100, 100})

    storage.createTime = storage.createTime or world.time()
    storage.start = storage.start or false

    storage.timer = storage.timer or depositHarvestLevel(config.getParameter("miningTime", 3), miningLevel, harvestLevel)
    sb.logInfo("%s", storage.timer)

    object.setConfigParameter("timer", storage.timer)

    objectUtils.setProgress("bar", "progress", storage.energy, maxEnergy, {0, 0, barSize[1], barSize[2]}, false)
    if storage.resources[1] == 0 then
        objectUtils.setColor("ore", "color", config.getParameter("color", "sf_black"))
    else
        objectUtils.setColor("ore", "color", config.getParameter("color", "volk_steel"))
    end
    message.setHandler(
        "addEnergy",
        function(_, _, energy)
            storage.energy = storage.energy + energy
            object.setConfigParameter("energy", storage.energy)
        end
    )
end

function depositHarvestLevel(time, ml, hl)
    return time * (hl / ml)
end

function loadDepositParameters()
    local arr = {
        depositRarity = rarity[1],
        items = deposit.items,
        color = deposit.color,
        counts = {weight, weight}
    }
    -- body
end

function update(dt)
    objectUtils.setProgress("bar", "progress", storage.energy, maxEnergy, {0, 0, barSize[1], barSize[2]}, false)
    if storage.energy >= consumeEnergy and storage.resources[1] > 0 then
        animator.rotateTransformationGroup("rotor", 0.05, {2.5, 2.5})
        local tm = world.time() - storage.createTime
        object.setConfigParameter("tm", tm)
        if tm >= storage.timer then
            storage.active = true
            storage.createTime = storage.createTime + storage.timer
            storage.energy = storage.energy - consumeEnergy
            storage.extracted = storage.extracted + 1
            storage.resources[1] = storage.resources[1] - 1
            world.containerAddItems(entity.id(), {name = util.weightedRandom(config.getParameter("items", {})), count = 1})
        end

        object.setConfigParameter("active", storage.active)
        object.setConfigParameter("energy", storage.energy)
        object.setConfigParameter("createTime", storage.createTime)
        object.setConfigParameter("extracted", storage.extracted)
        object.setConfigParameter("resources", storage.resources[1])
        return
    end
    if storage.resources[1] < 1 or storage.resources[1] <= 0 then
        objectUtils.setColor("ore", "color", config.getParameter("color", "sf_black"))
    end
    storage.active = false
    storage.createTime = world.time()
    object.setConfigParameter("resources", storage.resources[1])
    object.setConfigParameter("energy", storage.energy)
    object.setConfigParameter("active", storage.active)
end
