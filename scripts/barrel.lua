require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
    local localIndex = config.getParameter("localIndex", 1)
    local localDuration = config.getParameter("localDuration", 0)

    storage.duration = storage.duration or localDuration
    storage.index = storage.index or localIndex
    storage.created = storage.created or false
    storage.update = storage.update or true

    stages = config.getParameter("stages")

    animation = config.getParameter("animationConfig", nil)
    objectbreak = false

    animator.setGlobalTag("stage", storage.index)
end

function update(dt)
    
    local index = storage.index
    local stage = stages[index]

    timer = timer - dt
    if timer <= 0 then
        createstages(dt, index, stage)
        timer = 1
    end
end

function createstages(dt, index, stage)
    if storage.duration <= 0 and index ~= #stages then
        storage.duration = util.randomInRange(stage.duration)
    end

    if storage.duration > 0 and index ~= #stages then
        storage.duration = storage.duration - 1
        if storage.duration <= 0 then
            storage.index = index + 1
            storage.duration = 0
        end
    end

    if config.getParameter("animationCustom") and stage.harvest then
        animator.setParticleEmitterActive("animator", true)
    else
        animator.setParticleEmitterActive("animator", false)
    end

    animator.setGlobalTag("stage", index)

    if stage.harvest then
        object.setInteractive(true)
    end
end

function onInteraction()
    dropHarvest()
end

function dropHarvest()
    local stage = stages[storage.index]
    if stage.harvest then
        if stage.items then
            for i, item in pairs(stage.items) do
                world.spawnItem(item, object.position(), 1)
            end
            object.setInteractive(false)
        end
        if stage.pool then
        end
        if stage.setstage then
            storage.index = stage.setstage
            storage.duration = 0
        else
            objectbreak = true
            world.breakObject(entity.id(), false)
        end
        animator.playSound("open", 0)
    end
end

function die()
    local item = true
    local stage = stages[storage.index]
    local localstorage = config.getParameter("localstorage", false)
    local config = root.itemConfig(object.name()).config

    if stage.harvest and not objectbreak then
        dropHarvest()
    end

    if storage.index ~= #stages and localstorage and not objectbreak then
        config["localIndex"] = storage.index
        config["localDuration"] = storage.duration
        config.description = description(config.description)
        world.spawnItem(object.name(), object.position(), 1, config)

        item = false
    end

    if stage.destroyitem then
        item = false
    end

    if item then
        world.spawnItem(object.name(), object.position(), 1)
    end
end

function description(desc)
    local sum = 0
    for i, v in pairs(stages) do
        if v.duration then
            sum = sum + v.duration[2]
        end
        if i <= storage.index and v.duration then
            sum = sum - v.duration[2]
        end
    end
    sum = math.floor(sum + storage.duration)

    local m = math.floor(sum / 60)
    local s = math.floor(sum % 60)

    local time = string.format("\nRemaining time %s min : %s sec", m, s)
    local newDesc = "^orange;\n\n Stage " .. storage.index .. " / " .. #stages
    return desc .. newDesc .. time
end
