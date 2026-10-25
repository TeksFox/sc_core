require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/utils/ui_utils.lua"
require "/interface/scripts/ui_Components.lua"
tooltips = {}

function tooltips.creation(screenPosition, data, desc)
    local wName = widget.getChildAt(screenPosition)

    if not data then
        if wName ~= nil then
            local name = string.gsub(wName, ".", "", 1)
            local data = widget.getData(name)
            if data then
                if data.tooltips then
                    return tooltips.widgetName(data.tooltips)
                end
            end
        end
    else
        local text = data.friendlyname or data
        return tooltips.widgetName(text)
    end
end

function tooltips.widgetName(data)
    local text = data.text or data.description or data
    local wData = widget.getData("spectralText")

    --Для правильного отображения подсказки
    --Нужно создть невидимый текстовый виджет "spectralText", имеющий параметры положения текста а также ширину текста и размер шрифта
    --при его отсутствие текст будет не корректно отображаться
    widget.setText("spectralText", text)

    local tooltip = root.assetJson("/interface/craftingtooltip/widgettooltip.pane")
    if wData then
        if wData.fontSize then
            tooltip.text.fontSize = wData.fontSize
        end
    end
    local size = widget.getSize("spectralText")
    tooltip.background.fileBody = "/interface/craftingtooltip/tooltip_body.png?scalenearest=1;" .. size[2] + 10
    tooltip.text.value = copy(text)
    tooltip.text.position[2] = tooltip.text.position[2] + size[2] + 4

    return tooltip
end

function tooltips.imageBorder(image, bool)
    if bool then
        return image
    end
    return image
end

function tooltips.listCreation(data, widgets, types, title, parameters, output, require, shift)
    local outputSize = 0
    local requireSize = 0
    tooltip = root.assetJson("/interface/craftingtooltip/listTooltip.pane")
    footerSize = root.imageSize(tooltip.config.background.fileFooter)
    inputListSize = 0
    tooltipsBodySize = 0
    addedSize = 0
    local input = data.input or data

    if widgets and next(widgets) then
        for _, wName in pairs(widgets) do
            if tooltip.addedConfigs[wName] ~= nil then
                addedSize = addedSize + tooltip.addedConfigs[wName].size
                for k, v in pairs(tooltip.addedConfigs[wName].widgets) do
                    tooltip.config[k] = copy(v)
                    tooltip.config[k].position[2] = (tooltip.config[k].position[2] + addedSize + footerSize[2]) - tooltip.addedConfigs[wName].size
                end
            end
        end
    end
    if parameters then
        if parameters.largeImage then
            tooltip.config.largeImage.file = parameters.largeImage.image .. "?border=1;181824"
            tooltip.config.oldObjectName.value = parameters.largeImage.oldobjectName
        end
        if parameters.duration then
            tooltip.config.durationLabel.value = "Duration: " .. parameters.duration .. " sec"
        end
    end

    local inputSize = (tooltip.listSize[2] + tooltip.spacing[2]) * #input + tooltip.addedConfigs.itemList.children.text.widgetSize
    tooltips.createListSize(tooltip.addedConfigs.itemList, inputSize, "input")
    if parameters and parameters.items then
        requireSize = (tooltip.listSize[2] + tooltip.spacing[2]) * (#data.parameters.items or 1) + tooltip.addedConfigs.outputList.children.text.widgetSize
        tooltips.createListSize(tooltip.addedConfigs.requireList, requireSize, "require")
    end
    if output then
        outputSize = (tooltip.listSize[2] + tooltip.spacing[2]) * #data.output + tooltip.addedConfigs.outputList.children.text.widgetSize
        tooltips.createListSize(tooltip.addedConfigs.outputList, outputSize, "output")
    end

    if output then
        local output = data.output
        for i, item in pairs(output) do
            local iConf = root.itemConfig(item.name)
            local list = {
                type = "layout",
                layoutType = "basic",
                position = {3, ((tooltip.listSize[2] + tooltip.spacing[2]) * (#output - i))},
                size = tooltip.listSize,
                children = {}
            }

            list.children.replacable = copy(tooltip.config.replacable)

            if item.tag then
                list.children.replacable.visible = true
            end
            list.children.backItem = copy(tooltip.config.backItem)
            list.children.backItem.file = "/interface/craftingtooltip/parts/outputItemBack.png"
            list.children.icon = copy(tooltip.config.icon)
            list.children.icon.file = util.absolutePath(iConf.directory, iConf.config.inventoryIcon)
            list.children.border = copy(tooltip.config.border)
            list.children.border.file = "/interface/inventory/itemborder" .. string.lower(iConf.config.rarity) .. ".png"
            list.children.name = copy(tooltip.config.name)
            list.children.name.value = iConf.config.shortdescription
            list.children.count = copy(tooltip.config.count)
            if type(item.count) == "table" then
                list.children.count.value = string.format("x%s-%s", item.count[1], item.count[2])
            else
                list.children.count.value = string.format("x%s", item.count)
            end
            if item.weight then
                local weight = item.weight * 100
                list.children.weight = copy(tooltip.config.weight)
                list.children.weight.value = string.format("%.1f%%", item.weight * 100)

                if weight > 0 and weight <= 5 then
                    list.children.weight.color = "#820000"
                elseif weight > 5 and weight <= 10 then
                    list.children.weight.color = "red"
                elseif weight > 10 and weight <= 20 then
                    list.children.weight.color = "orange"
                elseif weight > 20 and weight <= 45 then
                    list.children.weight.color = "yellow"
                elseif weight > 45 and weight <= 50 then
                    list.children.weight.color = "green"
                elseif weight > 50 and weight <= 60 then
                    list.children.weight.color = "cyan"
                elseif weight > 60 and weight <= 100 then
                    list.children.weight.color = "violet"
                end
            end

            tooltip.config.outputItemList.children["item" .. i] = list
        end
        tooltip.config.inputItemList.position[2] = tooltip.config.inputItemList.position[2] + outputSize + requireSize
    end

    for i, item in pairs(input) do
        local iConf = root.itemConfig(item.name)
        local list = {
            type = "layout",
            layoutType = "basic",
            position = {3, ((tooltip.listSize[2] + tooltip.spacing[2]) * (#input - i))},
            size = tooltip.listSize,
            children = {}
        }

        list.children.replacable = copy(tooltip.config.replacable)

        if item.tag then
            list.children.replacable.visible = true
        end
        list.children.backItem = copy(tooltip.config.backItem)
        list.children.backItem.file = "/interface/craftingtooltip/parts/defaultItemBack.png"
        list.children.icon = copy(tooltip.config.icon)
        list.children.icon.file = util.absolutePath(iConf.directory, iConf.config.inventoryIcon)
        list.children.border = copy(tooltip.config.border)
        list.children.border.file = "/interface/inventory/itemborder" .. string.lower(iConf.config.rarity) .. ".png"
        list.children.name = copy(tooltip.config.name)
        list.children.name.value = iConf.config.shortdescription
        list.children.count = copy(tooltip.config.count)
        list.children.count.value = tooltips.compareNumbers(types, item, shift)

        tooltip.config.inputItemList.children["item" .. i] = list
    end

    tooltip.config.title.value = title or ". . ."
    tooltip.config.background.fileBody = tooltip.config.background.fileBody .. "?scalenearest=1;" .. tooltipsBodySize + addedSize
    tooltip.config.title.position[2] = footerSize[2] + 1 + tooltipsBodySize + addedSize + 7
    return tooltip.config
end

function tooltips.createListSize(config, size, type)
    tooltip.config[type .. "ItemList"] = config
    tooltip.config[type .. "ItemList"].position = {0, addedSize + footerSize[2] + 1}
    tooltip.config[type .. "ItemList"].size[2] = size
    tooltip.config[type .. "ItemList"].children.text.position[2] = size - 6
    tooltipsBodySize = tooltipsBodySize + size
end

function tooltips.compareNumbers(type, item, shift)
    local str = ""
    if type == "compare" then
        local itemCount = 0
        if shift then
            itemCount = item.count * 5
        else
            itemCount = item.count
        end
        str = string.format("%s/%s", ui.getAmount(item, shift), itemCount)
        str = "^" .. ui.setColor(item, shift) .. ";" .. str
    elseif type == "default" then
        str = string.format("%s", item.count)
    end
    return str
end
