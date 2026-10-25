require "/scripts/util.lua"
require "/interface/scripts/ui_tooltip.lua"
require "/interface/scripts/ui_Components.lua"

function init()
    SourceID = pane.containerEntityId()
    self.itemList = "itemScroll.list"

    harvestLevel = world.getObjectParameter(SourceID, "harvestLevel", 1)
    maxEnergy = world.getObjectParameter(SourceID, "maxenergy", 1000)

    local deposit = world.getObjectParameter(SourceID, "items")
    widget.clearListItems(self.itemList)
    for _, item in pairs(deposit) do
        local listWidget = widget.addListItem(self.itemList)
        local itemList = string.format("%s.%s", self.itemList, listWidget)
        local text = item[1] * 100

        widget.setItemSlotItem(itemList .. ".icon", item[2])
        widget.setText(itemList .. ".number", text .. "%")
    end
end

function update()
    local extracted = world.getObjectParameter(SourceID, "extracted", 0)
    local energy = world.getObjectParameter(SourceID, "energy", 0)
    local tmProgress = world.getObjectParameter(SourceID, "createTime")
    local maximumEu = world.getObjectParameter(SourceID, "maximumEu")
    local active = world.getObjectParameter(SourceID, "active")
    local extractTime = world.getObjectParameter(SourceID, "timer", 3)
    local energyConsume = world.getObjectParameter(SourceID, "consumeEnergy", 5)
    local resources = world.getObjectParameter(SourceID, "resources", 0)

    local energyForTime = (energy / energyConsume) * extractTime
    local duration = energyForTime - world.getObjectParameter(SourceID, "tm", 0)

    widget.setText("resourcesLabel", resources)
    widget.setText("extractedLabel", extracted)
    widget.setText("extractTimerLabel", string.format("%0.2f", extractTime))
    widget.setText("LevelLabel", world.getObjectParameter(SourceID, "miningLevel"))
    widget.setText("energyLabel", string.format("%s / %s", energy, maxEnergy))
    widget.setText("timeLabel", string.format("%sh %sm %.2fs", math.floor(duration / 3600), math.floor(duration / 60 % 60), duration % 60))

    if active then
        widget.setProgress("progressBar", (world.time() - tmProgress) / world.getObjectParameter(SourceID, "timer"))
    else
        widget.setProgress("progressBar", 0)
    end
end

function charge()
    local energyCells = root.assetJson("/configs/mineraldeposit/main.config:chargeItems")
    for i, item in pairs(energyCells) do
        if player.hasItem(item[1]) and player.hasCountOfItem(item[1]) > 0 then
            player.consumeItem({name = item[1], count = 1})
            world.sendEntityMessage(SourceID, "addEnergy", item[2])
        end
    end
end
