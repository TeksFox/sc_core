require "/scripts/util.lua"
require "/scripts/interp.lua"
recipe = {}

function recipe.init(objectName)
    local object = root.itemConfig(objectName).config
    local objectGroupFilter = object.objectfilters or object.interactData.filter
    local arr = {}
    local array = {}

    for i, rItem in pairs(root.assetJson(object.recipes)) do
        if root.itemConfig(rItem[1]) and player.blueprintKnown(rItem[1]) then
            for _, item in pairs(root.recipesForItem(rItem[1])) do
                if recipe.check(item.groups, objectGroupFilter) then
                    --sb.logInfo("%s --------- %s", rItem[1],recipe.itemConstructor(item, rItem, {}))
                    arr[rItem[1]] = recipe.itemConstructor(item, rItem, {})
                end
            end
        end
    end
    return arr
end

-- пакуем рецепт по новой схеме
function recipe.itemConstructor(item, parameters, array)
    array.timer = parameters[2]
    array.maxCount = 10
    array.duration = parameters[3] or 5
    array.input = item.input
    array.groups = item.groups
    array.output = item.output

    --sb.logInfo("%s--%s",constructRecipe.timer, constructRecipe.duration)

    return array
end

function recipe.check(item, object)
    for _, itemGroup in pairs(item) do
        for _, objectGroup in pairs(object) do
            if objectGroup == itemGroup then
                return true
            end
        end
    end
    return false
end
