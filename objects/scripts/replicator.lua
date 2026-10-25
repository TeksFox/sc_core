require "/scripts/util.lua"
require "/scripts/interp.lua"
require("/scripts/smarttubes/stCore_conduit.lua")
local OldInit = init

function init()
    if OldInit ~= nil then
        OldInit()
    end
    local name = object.name()
    recipes = root.assetJson(config.getParameter("recipes"))
    storage.crafting = storage.crafting or {}
    storage.completeItems = storage.completeItems or {}
    conectedContainer = nil

    message.setHandler(
        "recipeLoad",
        function(_, _, recipe)
            storage.crafting = recipeAdd(recipe, storage.crafting)
        end
    )
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
    -- body
end

local OldUpdate = update
function update(dt)
    if OldUpdate ~= nil then
        OldUpdate(dt)
    end
    local node = object.isOutputNodeConnected(0)
    storage.crafting = processing()

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
    object.setConfigParameter("crafts", storage.crafting)

end

function magnitude()
    return world.magnitude(object.position(), world.entityPosition(conectedContainer)) < 10
end

function recipeAdd(recipe, crafts)
    local name = recipe.output.name

    if crafts[name] == nil then
        crafts[name] = {recipes = {}, maxCount = recipe.maxCount, output = recipe.output.count, input = recipe.input, parameters = recipe.output.parameters}
    end

    if next(crafts[name].recipes) then
        local duration = 0
        for il, item in pairs(crafts[name].recipes) do
            if il == #crafts[name].recipes then
                duration = duration + (item[1] - world.time())
            else
                duration = duration + item[2]
            end
        end
        recipe.duration[1] = recipe.duration[1] + duration
        table.insert(crafts[name].recipes, 1, recipe.duration)
        return crafts
    else
        table.insert(crafts[name].recipes, 1, recipe.duration)
        return crafts
    end
end

function processing(crafts, id)
    local crafts = storage.crafting
    if next(crafts) then
        for i, item in pairs(crafts) do
            if item.recipes[#item.recipes][1] <= world.time() then
                if not storage.completeItems[i] then
                    storage.completeItems[i] = {name = i, count = item.output, parameters = item.parameters}
                else
                    storage.completeItems[i].count = storage.completeItems[i].count + item.output
                end

                crafts[i].recipes[#item.recipes] = nil
            end
            if not next(crafts[i].recipes) then
                crafts[i] = nil
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
            sb.logInfo("%s", items.input)
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
