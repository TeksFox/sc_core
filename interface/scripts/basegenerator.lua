local SourceID
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
function init()
    SourceID = pane.containerEntityId()

    self.itemList = "itemScroll.list"
    local euConfig = world.getObjectParameter(SourceID, "euConfig")
    --

    local inOut = string.format("%s", math.ceil(32 * 2 ^ (euConfig.euEnergyLevel - 1)))
    widget.setText("maxInput", inOut)
    widget.setText("maxStorage", euConfig.euStorage)
end

function update()
    local heatPercent = world.getObjectParameter(SourceID, "currentEu", 0)
    widget.setProgress("progressBar", heatPercent)

    widget.setProgress("processBar", world.getObjectParameter(SourceID, "currfuel", 0) / world.getObjectParameter(SourceID, "fuelmax", 0))
end
function buttonCall()
    player.interact("ScriptPane", "/interface/scripted/reagentlist/reagentlist.ui", SourceID)
end
