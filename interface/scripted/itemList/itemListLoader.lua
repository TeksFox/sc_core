function recipeloader(config)
    local recipes = {}
    local pool = nil
    for i, res in pairs(config.recipefile) do
        local data = root.assetJson(res)
        pool = data.pool
        for i, category in pairs(data.recipes) do
            local insert = i
            for i, unpack in pairs(category) do
                unpack["category"] = insert
                unpack["id"] = unpack.name .. "." .. insert .. "." .. i
                table.insert(recipes, unpack)
            end
        end
    end

    object.setConfigParameter("pool", pool)
    object.setConfigParameter("recipes", recipes)
    object.setConfigParameter("toolslot", config.toolslotrange)
    object.setConfigParameter("tool", config.tool)
    object.setConfigParameter("uiconfig", config.uiconfig)
end

function trigger()
    message.setHandler(
        "trigger",
        function(_, _, params)
            storage.active = true
        end
    )
    self.trigger = true
end

function recipeCheck()
    if next(storage.recipes) then
        return true
    end
    return false
end

function modules()
    return not (not next(storage.modules))
end

function level()
    return storage.level > 1
end

function currEu()
    return storage.currentEu > 0
end

function moduleName()
    local name = ""
    for k, v in pairs(storage.modules) do
        name = name .. string.format("%s, ", root.itemConfig(v).config.shortdescription)
    end
    return name
end
