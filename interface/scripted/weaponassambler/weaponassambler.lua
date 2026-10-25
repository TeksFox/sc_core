require "/scripts/util.lua"
local SourceID
local SlotItem
local UpdateStats

function init()
    selectedPart = "none"
    itemSlot = "itemupgrade.itemSlot"
    itemCopySlot = "itemupgrade.itemCopySlot"
    canvas = widget.bindCanvas("itemupgrade.canvas")

    selectedItem = nil
    forceReload = true

    selectedData = nil

    weaponSelectorList()
end

function update()
    canvas:clear()

    canvasDrawPreview(weaponData, selectedPart)

    forceReload = false
end

function weaponSelectorList()
    local listItems = "itemSelector.scroll.list"

    widget.clearListItems(listItems)
    for _, item in pairs(player.itemsWithTag("customweapon")) do
        local listWidget = widget.addListItem(listItems)
        local itemList = string.format("%s.%s", listItems, listWidget)

        widget.setItemSlotItem(itemList .. ".icon", item)
        widget.setText(itemList .. ".name", root.itemConfig(item.name).config.shortdescription .. "  ^orange;ID" .. item.parameters.pid)

        widget.setData(
            itemList,
            {
                pid = item.parameters.pid,
                config = item
            }
        )
    end
end

function selectWeapon(...)
    updateSelected()
end

function selectWeapon(...)
    updateSelected()
    if selectedData and widget.itemSlotItem(itemSlot) and widget.itemSlotItem(itemSlot).parameters.pid ~= selectedData.pid or selectedData and not widget.itemSlotItem(itemSlot) then
        sb.logInfo("%s", selectedData)
        widget.setItemSlotItem(itemSlot, {name = selectedData.config.name, count = 1, parameters = selectedData.config.parameters})
    end
end

function updateSelected()
    local itemList = widget.getListSelected("itemSelector.scroll.list")
    selectedData = itemList and widget.getData(string.format("%s.%s", "itemSelector.scroll.list", itemList)) or nil
end

function selectToUpgrade()
    if widget.itemSlotItem(itemSlot) then
        widget.setItemSlotItem(itemCopySlot, widget.itemSlotItem(itemSlot))
        player.consumeItemWithParameter("pid", widget.itemSlotItem(itemSlot).parameters.pid, 1)
        widget.setVisible("itemSelector", false)
        widget.setVisible("itemupgrade", true)
        weaponSelectorList()
    end
    -- body
end

function setWeapon()
end

function descriptionUpdate()
end

function canvasDrawPreview()
    local data = widget.itemSlotItem(itemSlot)
    if data then
        local item = root.itemConfig(data.name)
        local partImages = item.config.animationParts
        local partParameters = item.config.animationCustom.animatedParts.parts
        local scale = config.getParameter("canvasScale", 2)
        local fullImageSize = {0, 0}
        local size = {canvas:size()[1] / 2, canvas:size()[2] / 2}
        local imageSize = setImageSize(partImages, scale)

        for name, parameters in pairs(partParameters) do
            local posX = (parameters.properties.offset[1] * 8) * scale
            local posY = (parameters.properties.offset[2] * 8) * scale

            if selectedPart == name then
                canvas:drawImage(partImages[name] .. "?border=1;FFFFFF", {size[1] + posX - imageSize, size[2] + posY - 5}, scale, nil, true)
            else
                canvas:drawImage(partImages[name], {size[1] + posX - imageSize, size[2] + posY - 5}, scale, nil, true)
            end
        end

        local partBase = root.assetJson(util.absolutePath(item.directory, item.config.partconfig))

        for name, part in pairs(partImages) do
            widget.setImage("itemupgrade." .. name .. "Image", part .. "?border=1;D8E7FF")
        end
        widget.setText("itemupgrade.DPSLabel", item.config.tooltipFields.dpsLabel)
        widget.setText("itemupgrade.DamageLabel", item.config.tooltipFields.damagePerShotLabel)
        widget.setText("itemupgrade.FireTimeLabel", item.config.tooltipFields.speedLabel)

        widget.setText("itemupgrade.CritLabel", item.config.tooltipFields.crit)
        widget.setText("itemupgrade.CritMultLabel", item.config.tooltipFields.critMult)
    end
end

function selectPart(wName, wData)
    if selectedPart ~= wData.option then
        selectedPart = wData.option
    else
        selectedPart = "none"
    end
end

-- selectedPart

function setImageSize(table, scale)
    local x = 0
    for name, image in pairs(table) do
        if checkPart(name) then
            x = x + root.imageSize(image)[1]
        end
    end
    return x / 2
end

function checkPart(name)
    local noIgnore = {"butt", "middle", "forend", "barrel", "muzzle"}
    for _, i in pairs(noIgnore) do
        if name == i then
            return true
        end
    end
    return false
    -- body
end

function weaponSelector()
    local list = awd
end

function uninit()
    if copyData then
        player.giveItem({name = copyData.config.name, count = 1, parameters = copyData.config.parameters})
    end
end
--
