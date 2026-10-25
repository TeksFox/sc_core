ui_utils = {}
local screenPosition = {0, 0}
local screenPositionOld = {0, 0}

function ui_utils.dataReplacer(oldData, newData, default)
    if oldData ~= newData or oldData == nil then
        oldData = newData
    end
    return oldData
end

function ui_utils.listDataExtract(list)
    return widget.getData(string.format("%s.%s", list, widget.getListSelected(list))) or nil
end

function ui_utils.visibleGroup(arr, bool)
    for _, name in pairs(arr) do
        widget.setVisible(name, bool)
    end
end

function ui_utils.enableGroup(arr, bool)
    for _, name in pairs(arr) do
        widget.setButtonEnabled(name, bool)
    end
end

function ui_utils.craftConsume(items)
    for k, v in pairs(items) do
        if ui_utils.isCurrency(v) then
            player.consumeCurrency(v.name, v.count)
        else
            player.consumeItem({v.name, v.count})
        end
    end
end

function ui_utils.hasIngredients(config)
    for k, v in pairs(config) do
        if not ui_utils.hasEnough(v) then
            return false
        end
    end
    return true
end

function ui_utils.canCraft(config)
    local input = config.input or config
    return ui_utils.hasIngredients(input)
end

function ui_utils.hasEnough(item)
    return ui_utils.getAmount(item) >= item.count
end

function ui_utils.getAmount(item)
    if ui_utils.isCurrency(item) then
        return player.currency(ui_utils.currencyType(item))
    else
        return player.hasCountOfItem(item.name)
    end
end

function ui_utils.isCurrency(item)
    return root.itemType(item.name) == "currency"
end

function ui_utils.currencyType(item)
    if item.parameters and item.parameters.currency then
        return item.parameters.currency
    end
    return root.itemConfig(item).config["currency"]
end

function ui_utils.dataSelectedMultipler(data, mult)
    for i, item in pairs(data.input) do
        data.input[i].count = item.count * mult
    end
    return data
end

function ui_utils.setColor(item)
    if ui_utils.hasEnough(item) then
        return "green"
    end
    return "red"
end
