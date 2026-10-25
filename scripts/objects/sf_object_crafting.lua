require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
    storage.crafting = storage.crafting or {}
    animation = config.getParameter("defaultAnimation", false)
    storage.completeItems = storage.completeItems or {}
    storage.processing = storage.processing or false
    conectedContainer = nil
    craftActive = true
    craftMessages()

    -- animator.setAnimationState("activeState", "idle")
end

function createStorage(line)
    local arr = {}
    for i = 1, line do
        table.insert(arr, {})
    end
    return arr
    -- body
end

function nodeCheckContainer(ids)
    for id, _ in pairs(ids) do
        local type = world.getObjectParameter(id, "objectType", "none")
        if type == "container" then
            conectedContainer = id
            return true
        end
    end
    return false
end

function update(dt)
    processing(storage.crafting)
    object.setConfigParameter("crafts", storage.crafting)
    object.setConfigParameter("completeItems", storage.completeItems)
end

function magnitude()
    return world.magnitude(object.position(), world.entityPosition(conectedContainer)) < 10
end

function addRecipe(recipe, crafts)
    local r = recipe.output.name
    if not crafts[r] then
        crafts[r] = {start = world.time() + recipe.duration, duration = recipe.duration, counts = {recipe.count, 0}}
    else
        if crafts[r].counts[1] <= 0 then
            crafts[r].start = world.time() + recipe.duration
        end
        crafts[r].counts[1] = crafts[r].counts[1] + recipe.count
    end
    crafts[r].input = recipe.input
    crafts[r].output = recipe.output
    return crafts
end

function giveCraftItem(name, crafts)
    if crafts[name].counts[1] > 0 then
        crafts[name].counts[2] = 0
    else
        crafts[name] = nil
    end
    return crafts
end

function processing(crafts, id)
    for i, _ in pairs(crafts) do
        if i ~= nil and crafts[i].counts[1] ~= 0 then
            animator.setAnimationState("activeState", "active")
        end
        if crafts[i].counts[1] >= 1 and world.time() > crafts[i].start then
            crafts[i].start = crafts[i].start + crafts[i].duration
            crafts[i].counts[1] = crafts[i].counts[1] - 1
            crafts[i].counts[2] = crafts[i].counts[2] + 1
        elseif crafts[i].counts[1] == 0 and crafts[i].start ~= 0 then
            crafts[i].start = 0
            animator.setAnimationState("activeState", "idle")
        end
    end

    storage.crafting = crafts
end

function die()
    local name = object.name()
    local arr = {storage.completeItems, storage.crafting}
    if next(storage.crafting) then
        for _, items in pairs(storage.crafting) do
            if next(items) then
                for i, item in pairs(items.input) do
                    local count = 1000
                    local itemCount = item.count * items.counts[1]
                    repeat
                        if itemCount < count then
                            count = itemCount
                        end
                        world.spawnItem({name = item.name, count = itemCount, parameters = item.parameters}, object.position())
                        itemCount = itemCount - count
                    until itemCount == 0
                end
                for i = 1, 100 do
                    local count = 1000
                    local itemCount = items.output.count * items.counts[2]
                    repeat
                        if itemCount < count then
                            count = itemCount
                        end
                        world.spawnItem({name = items.output.name, count = itemCount}, object.position())
                        itemCount = itemCount - count
                    until itemCount == 0
                    break
                end
            end
        end
    end
end

function onInteraction()
    local line = config.getParameter("line")
    local interact = config.getParameter("interactAction")
    local config = root.assetJson(config.getParameter("interactData"))
    local size = {158, 33}

    return {interact, config, entity.id()}
end

function craftMessages()
    message.setHandler(
        "add",
        function(_, _, widgetData)
            storage.crafting = addRecipe(widgetData, storage.crafting)
        end
    )
    message.setHandler(
        "recipeRemove",
        function(_, _, widgetData)
            storage.crafting[widgetData].counts[1] = 0

            animator.animationState("activeState", "idle")
        end
    )
    message.setHandler(
        "giveall",
        function(_, _, name)
            storage.crafting = giveCraftItem(name, storage.crafting)
        end
    )
end

function animationState(state, stateName)
    if animation then
        animator.setAnimationState(state, stateName)
    end
end
