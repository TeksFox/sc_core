function hasIngredients(config)
    for k, v in pairs(config) do
        if not hasEnough(v) then
            return false
        end
    end
    return true
end

function canCraft(config)
    return hasIngredients(config.input)
end

function hasEnough(item)
    return getAmount(item) >= item.count
end

function getAmount(item)
    if isCurrency(item) then
        return player.currency(currencyType(item))
    else
        return player.hasCountOfItem(item.name)
    end
end

function isCurrency(item)
    return root.itemType(item.name) == "currency"
end

function currencyType(item)
    if item.parameters and item.parameters.currency then
        return item.parameters.currency
    end
    return root.itemConfig(item).config["currency"]
end
