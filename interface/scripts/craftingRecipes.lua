recipe = {}

function recipe.load(loadRecipe, id)
    local arr = {}


    for i, item in pairs(loadRecipe) do
        if (player.blueprintKnown(item.name) or player.isAdmin()) then
            item.duration = item.duration * durationMultipler
            if maxItemInLine then
                item.maxCount = maxItemInLine
            end
            table.insert(arr, item)
        end
    end
    return arr
end


