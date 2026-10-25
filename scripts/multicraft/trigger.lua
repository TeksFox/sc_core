require "/scripts/util.lua"
require "/scripts/interp.lua"

local SourceID
function init()
    SourceID = pane.containerEntityId()
    reagent = world.getObjectParameter(SourceID, "reagentConfig", nil)

    local storageModule = world.getObjectParameter(SourceID, "storageModule", {})

    for k, v in pairs(storageModule) do
        widget.setItemSlotItem(k, v)
    end
end

function update()
    local storageClock = world.getObjectParameter(SourceID, "storageClock", 0)
    local storageWait = world.getObjectParameter(SourceID, "storageWait", 0)
    local storageMin = world.getObjectParameter(SourceID, "storageMin", 0)
    local clockMax = world.getObjectParameter(SourceID, "storageClockMax", 10000)
    local euProgress = world.getObjectParameter(SourceID, "currentEu", 0)
    local maximumEu = world.getObjectParameter(SourceID, "maximumEu", 0)

    --local reagent = world.getObjectParameter(SourceID, "reagent", nil)

    local level = world.getObjectParameter(SourceID, "level", 1)
    if level ~= 1 or not levelConfig then
        widget.setVisible("modulelockerTitle", false)
        widget.setVisible("upgrade_speedSlot", true)
        widget.setVisible("upgrade_energySlot", true)
        widget.setVisible("upgrade_levelSlot", true)
    end

    local progress = 0

    if (storageWait ~= -1) then
        if (storageClock - storageWait) > (clockMax / 2) then
            storageWait = storageWait + clockMax
            storageMin = storageMin + clockMax
        end
        progress = 1 - ((storageWait - storageClock) / (storageWait - storageMin))
    end

    --widget.setProgress("reagentBar", 0+ reagent.curCount / reagent.maxCount)
    --widget.setText("reagentName", root.itemConfig(reagent.name).config.shortdescription)
    --widget.setText("reagentCount", reagent.curCount)

    widget.setProgress("progressBar", progress)
    widget.setProgress("energyBar", euProgress)
    widget.setText("batterytext", string.format("%s", math.floor(maximumEu * euProgress)))
    --widget.setText("batterytext", string.format("%s/%s", math.floor(maximumEu * euProgress), math.floor(maximumEu)))
end

function trigger()
    world.sendEntityMessage(SourceID, "trigger")
end

function recipelist()
    --world.sendEntityMessage(player.id(),"deployMech")
    player.interact("ScriptPane", "/interface/scripted/itemList/itemList.ui", SourceID)
end
--
function reagentslist()
    player.interact("ScriptPane", "/interface/scripted/itemList/reagentslist.ui")
end

function moduleswap(widgetName)
    local currItem = widget.itemSlotItem(widgetName)
    local item = player.swapSlotItem()

    local storageModule = world.getObjectParameter(SourceID, "storageModule", {})

    local module = root.itemConfig(item or "copperbar")
    local config = module.config.moduleType or nil

    sb.logInfo("Message handler %s", config)
    for k, v in pairs(storageModule) do
        widget.setItemSlotItem(k, v)
    end
    if config == widgetName or not item then
        if item and item.count > 1 and not currItem then
            item.count = item.count - 1
            widget.setItemSlotItem(widgetName, {count = 1, name = item.name, parameters = item.parameters})
            player.setSwapSlotItem(item)

            storageModule[widgetName] = item.name
        elseif item and item.count > 1 and currItem then
            -- Do nothing
        else
            widget.setItemSlotItem(widgetName, item)
            player.setSwapSlotItem(currItem)

            storageModule[widgetName] = item
        end
    end
    world.sendEntityMessage(SourceID, "modules", storageModule)
end
