require "/scripts/util.lua"
require "/scripts/interp.lua"

require "/interface/scripts/ui_tooltip.lua"

local SourceID

function init()
    SourceID = pane.sourceEntity() or pane.sourceEntity()
    drillReady = false
    self.itemList = "itemScroll.list"

    pane.setTitle("Resource deposit", world.getObjectParameter(SourceID, "objectRes").depositRarity)
    depositType = world.getObjectParameter(SourceID, "deposittype", "solid")

    local title = depositType
    title = title:gsub("^%l", string.upper)
    widget.setText("typeLabel", title)

    widget.setButtonEnabled("start", false)

    local deposit = world.getObjectParameter(SourceID, "objectRes")
    widget.clearListItems(self.itemList)
    widget.setText("depositLevelLabel", world.getObjectParameter(SourceID, "harvestLevel", 1))
    widget.setText("countLabel", string.format("%s", deposit.counts[2]))
    for _, item in pairs(deposit.items) do
        local listWidget = widget.addListItem(self.itemList)
        local itemList = string.format("%s.%s", self.itemList, listWidget)
        local text = item[1] * 100

        widget.setItemSlotItem(itemList .. ".icon", item[2])
        widget.setText(itemList .. ".number", text .. "%")
    end
end

function createTooltip(screenPosition)
    if widget.inMember("upgrade", screenPosition) then
        local iConf = root.itemConfig("stationarydrilling")
        local image = iConf.config.largeImage or iConf.config.placementImage or ""
        local largeImage = {
            image = util.absolutePath(iConf.directory, image),
            oldobjectName = iConf.config.shortdescription
        }
        local recipe = world.getObjectParameter(SourceID, "upgrade").upgradeMaterials
        return tooltips.listCreation(recipe, {"largeImage"}, "compare", "UPGRADE INGREDIENTS", {largeImage = largeImage})
    end
end

function starDrillPlace()
    local item = widget.itemSlotItem("drillSlot") or false
    if item and drillReady then
        if player.hasCountOfItem(item.name) > 0 then
            world.sendEntityMessage(SourceID, "placeDrill", item.name)
            player.consumeItem(item.name, 1)
        else
            local text = util.randomFromList(config.getParameter("text").activateText)
            widget.setText("drillLabel", string.format("^red;%s", text))
            widget.setButtonEnabled("start", false)
            widget.setItemSlotItem("drillSlot", "xxx")
            drillReady = false
        end
    end
end

function drillSlot()
    if player.swapSlotItem() then
        widget.setItemSlotItem("drillSlot", {name = player.swapSlotItem().name, count = 1})
    else
        widget.setItemSlotItem("drillSlot", "")
    end
    local item = widget.itemSlotItem("drillSlot") or false
    if item and player.hasCountOfItem(item.name) > 0 then
        widget.setText("drillLabel", "^green; The drill is the right type, press ^orange;Start^green; to begin drilling! Don't forget to charge it")
        drillReady = true
        widget.setButtonEnabled("start", true)
        local itemParam = root.itemConfig(item).config
        if itemParam.drillType and itemParam.drillType == depositType then
        end
        if not itemParam.drillType then
            widget.setText("drillLabel", "^red; This item a not a drill")
            widget.setButtonEnabled("start", false)
            drillReady = false
        end

        if itemParam.drillType and itemParam.drillType ~= depositType then
            widget.setText("drillLabel", "^red; Drill not a wrong type")
            widget.setButtonEnabled("start", false)
            drillReady = false
        end
    else
        widget.setText("drillLabel", "^orange; Set drill in item slot!")
        widget.setButtonEnabled("start", false)
        drillReady = false
    end
end
