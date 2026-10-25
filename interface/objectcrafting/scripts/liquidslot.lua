require "/scripts/gui/util.lua"
local oldinit = init
local oldupdate = update

function init()
    if oldinit ~= nil then
        oldinit()
    end
    SourceID = pane.containerEntityId()

    pacrameterCheck = world.getObjectParameter(SourceID, "guiParameter", "default")
    paramList = root.assetJson("/configs/guiConf.config")[pacrameterCheck]
    slot = paramList.slotrange
    name = nil
    liquidconfig = config.getParameter("liquid", "liquidwater")
end

function update()
    if oldupdate ~= nil then
        oldupdate()
    end
    local items = itemsInContainerRange(SourceID, slot[1], slot[2])
    local liqCount = 0
    local count = 0
    local progress = 0
    for i, liquid in pairs(items) do
        if items[i].name == liquidconfig then
            liqCount = liqCount + items[i].count
            count = count + 1


            progress = liqCount / (1000 * count)
        end
    end
    widget.setText("lblstatus", liqCount.."/"..(1000 * count))
    widget.setProgress("liquidwaterBar", progress)
end
