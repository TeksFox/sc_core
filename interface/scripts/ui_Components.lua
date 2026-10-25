require "/interface/scripts/ui_storage_functions.lua"
ui = {}
local screenPosition = {0, 0}
local screenPositionOld = {0, 0}

function ui.init(name)
    player.setProperty("personalstorage", player.getProperty("personalstorage", {}))

    local object = root.itemConfig(name).config
    if type(object.uiconfig) == "table" then
        self.uiconfig = object.uiconfig
    else
        self.uiconfig = root.assetJson("/configs/uiconfigs/" .. object.uiconfig .. ".uiconfig")
    end

    ui.createCategoryList(self.uiconfig.category)
end

function ui.createCategoryList(category)
    local categorySort = {}
    for _, config in pairs(category) do
        table.insert(categorySort, config)
    end
    widget.clearListItems("categorylist")
    for i, config in ipairs(categorySort) do
        local cListWidget = widget.addListItem("categorylist")
        local cList = string.format("%s.%s", "categorylist", cListWidget)
        if config.selected then
            widget.setListSelected("categorylist", cListWidget)
            self.curFilter = config.category
        end
        widget.setImage(cList .. ".icon", config.icon or "/interface/scripted/itemList/icons/error.png")
        widget.setData(cList, config.category)

        self.toolTipList[string.format("%s.%s", "categorylist", cListWidget)] = config
    end
end

function ui.dataReplacer(oldData, newData, default)
    if oldData ~= newData or oldData == nil then
        oldData = newData
    end
    return oldData
end

function ui.listDataExtract(list)
    return widget.getData(string.format("%s.%s", list, widget.getListSelected(list))) or nil
end

function ui.visibleGroup(arr, bool)
    for _, name in pairs(arr) do
        widget.setVisible(name, bool)
    end
end

function ui.enableGroup(arr, bool)
    for _, name in pairs(arr) do
        widget.setButtonEnabled(name, bool)
    end
end

function ui.addItems(item)
    if ui.isCurrency(item) then
        player.addCurrency(item.name, item.count)
    else
        if ps.getEnabled() and root.itemType(item.name) == "generic" then
            ps.giveItem(item.name, item.count)
        else
            player.giveItem({item.name, item.count})
        end
    end
end
function ui.consumeItems(items, shift)
    local count = 1
    if shift then
        count = 5
    end
    for k, v in pairs(items) do
        if ui.isCurrency(v) then
            player.consumeCurrency(v.name, v.count * count)
        else
            if ps.getEnabled() and root.itemType(v.name) == "generic" then
                ps.consumeItem(v.name, v.count * count)
            else
                player.consumeItem({v.name, v.count * count})
            end
        end
    end
end

function ui.hasIngredients(input, shift)
    for _, item in pairs(input) do
        if not ui.hasEnough(item, shift) then
            return false
        end
    end
    return true
end

function ui.canCraft(input, shift)
    return ui.hasIngredients(input, shift)
end

function ui.hasEnough(item, shift)
    if shift then
        return ui.getAmount(item, shift) >= item.count * 5
    end
    return ui.getAmount(item) >= item.count
end

function ui.getAmount(item)
    if ui.isCurrency(item) then
        return player.currency(ui.currencyType(item))
    else
        return player.hasCountOfItem(item.name)
    end
end

function ui.isCurrency(item)
    return root.itemType(item.name) == "currency"
end

function ui.currencyType(item)
    if item.parameters and item.parameters.currency then
        return item.parameters.currency
    end
    return root.itemConfig(item).config["currency"]
end

function ui.dataSelectedMultipler(data)
    for i, item in pairs(data.input) do
        data.input[i].count = item.count
    end
    return data
end

function ui.setColor(item, shift)
    if ui.hasEnough(item, shift) then
        return "green"
    end
    return "red"
end

function ui.progressImage(name, progress, colorName, resourceColors)
    local arr
    if type(name) == "table" then
        arr = name
    else
        arr = widget.getData(name) or name
    end
    return arr.file .. ui.progressImageColor(colorName, resourceColors) .. ui.progressImageCrop(progress, arr.file, arr.direction)
end

function ui.progressImageColor(colorName, resourceColors)
    local color = root.assetJson(resourceColors)[colorName]
    local paletteSwaps = ""
    for k, v in pairs(color) do
        paletteSwaps = string.format("%s?replace=%s=%s", paletteSwaps, k, v)
    end
    return paletteSwaps
end

function ui.progressImageCrop(progress, file, direction)
    local image = root.nonEmptyRegion(file)
    if direction == "horizontal" then
        return string.format("?crop=%s;%s;%s;%s", image[1], image[2], image[3] * progress, image[4])
    else
        return string.format("?crop=%s;%s;%s;%s", image[1], image[2], image[3], image[4] * progress)
    end
end
