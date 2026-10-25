require "/scripts/util.lua"
require "/scripts/interp.lua"
require("/scripts/smarttubes/stCore_conduit.lua")

local OldInit = init

function init()
    local name = object.name()

    energy = config.getParameter("euConfig", nil)
    animation = config.getParameter("defaultAnimation", false)
    connect = config.getParameter("connectEnabled", false)

    recipes = root.assetJson(config.getParameter("recipes"))
    storage.crafting = storage.crafting or createCraftStorage(config.getParameter("line", 3))
    storage.completeItems = storage.completeItems or {}
    conectedContainer = nil
    if animation then
        animator.setAnimationState("activeState", "idle")
    end

    message.setHandler(
        "recipeLoad",
        function(_, _, recipe)
            storage.crafting = recipeAdd(recipe, storage.crafting)
        end
    )
    message.setHandler(
        "recipeRemove",
        function(_, _, i)
            storage.crafting[i] = {}
            if animation then
                animator.setAnimationState("activeState", "idle")
                sb.logInfo("%s", animation)
            end
        end
    )
    message.setHandler(
        "giveall",
        function(_, _)
            storage.completeItems = {}
        end
    )
    if OldInit ~= nil then
        OldInit()
    end
end

function createCraftStorage(line)
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

local OldUpdate = update
function update(dt)
    if OldUpdate ~= nil then
        OldUpdate(dt)
    end
    storage.crafting = processing()
    connectUpdate()
    object.setConfigParameter("crafts", storage.crafting)
    object.setConfigParameter("completeItems", storage.completeItems)
end

function magnitude()
    return world.magnitude(object.position(), world.entityPosition(conectedContainer)) < 10
end

function onInteraction()
    local line = config.getParameter("line")
    local interact = config.getParameter("interactAction")
    local config = root.assetJson(config.getParameter("interactData"))
    local size = {158, 33}
    local spacing = {0, 2}
    for i = 1, line do
        local item = {
            type = "layout",
            layoutType = "basic",
            visible = true,
            size = {158, 33},
            position = {0, (size[2] + spacing[2]) * (i - 1)},
            children = {}
        }
        item.children.back = copy(config.list.back)
        item.children.name = copy(config.list.name)
        item.children.maxcount = copy(config.list.maxcount)
        item.children.progressBar = copy(config.list.progressBar)
        item.children.icon = copy(config.list.icon)
        item.children["addone_" .. i] = copy(config.list.addone)
        item.children["addfive_" .. i] = copy(config.list.addfive)
        item.children["remove_" .. i] = copy(config.list.remove)

        config.gui.craftingScroll.children["item" .. i] = item
    end

    return {interact, config, entity.id()}
end

function recipeAdd(recipe, crafts)
    local name = recipe.output.name

    if crafts[recipe.slot] == nil or crafts[recipe.slot] and not next(crafts[recipe.slot]) then
        crafts[recipe.slot] = {recipes = {}, maxCount = recipe.maxCount, output = recipe.output, input = recipe.input, parameters = recipe.output.parameters}
    end

    if next(crafts[recipe.slot].recipes) then
        local duration = 0
        for il, item in pairs(crafts[recipe.slot].recipes) do
            if il == #crafts[recipe.slot].recipes then
                duration = duration + (item[1] - world.time())
            else
                duration = duration + item[2]
            end
        end
        recipe.duration[1] = recipe.duration[1] + duration
        table.insert(crafts[recipe.slot].recipes, 1, recipe.duration)
        return crafts
    else
        table.insert(crafts[recipe.slot].recipes, 1, recipe.duration)
        return crafts
    end
end

function processing(crafts, id)
    local crafts = storage.crafting
    if next(crafts) then
        for i, item in pairs(crafts) do
            if next(item) then
                if animation then
                    animator.setAnimationState("activeState", "active")
                end
                if item.recipes[#item.recipes][1] <= world.time() then
                    if not storage.completeItems[item.output.name] then
                        storage.completeItems[item.output.name] = {name = item.output.name, count = item.output.count, parameters = item.parameters}
                    else
                        storage.completeItems[item.output.name].count = storage.completeItems[item.output.name].count + item.output.count
                    end

                    crafts[i].recipes[#item.recipes] = nil
                end

                if not next(crafts[i].recipes) then
                    crafts[i] = {}
                    if animation then
                        animator.setAnimationState("activeState", "idle")
                    end
                end
            end
        end
    end
    return crafts
end

function die()
    local name = object.name()
    local arr = {storage.completeItems, storage.crafting}
    if next(storage.crafting) then
        for _, items in pairs(storage.crafting) do
            if next(items) then
                for i, item in pairs(items.input) do
                    local count = 1000
                    local itemCount = item.count * #items.recipes
                    repeat
                        if itemCount < count then
                            count = itemCount
                        end
                        world.spawnItem({name = item.name, count = itemCount, parameters = item.parameters}, object.position())
                        itemCount = itemCount - count
                    until itemCount == 0
                end
            end
        end
    end
    if next(storage.completeItems) then
        for i, item in pairs(storage.completeItems) do
            local count = 1000
            local itemCount = item.count
            repeat
                if itemCount < count then
                    count = itemCount
                end
                world.spawnItem({name = item.name, count = itemCount, parameters = item.parameters}, object.position())
                itemCount = itemCount - count
            until itemCount == 0
        end
    end
end

function connectUpdate(...)
    if connect then
        local node = object.isOutputNodeConnected(0)
        if node and nodeCheckContainer(object.getOutputNodeIds(0)) then
            object.setOutputNodeLevel(0, true)
            object.setConfigParameter("conected", true)
        else
            object.setOutputNodeLevel(0, false)
            object.setConfigParameter("conected", false)
        end

        if next(storage.completeItems) and node and nodeCheckContainer(object.getOutputNodeIds(0)) and magnitude() then
            sb.logInfo("%s", magnitude())
            for i, item in pairs(storage.completeItems) do
                world.containerAddItems(conectedContainer, {name = item.name, count = item.count, parameters = item.parameters})
                storage.completeItems[i] = nil
            end
        end
    end
end