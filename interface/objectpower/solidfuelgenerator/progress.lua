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
    
    local inOut = string.format("%s", math.ceil(32 * 2^(euConfig.euEnergyLevel - 1)))
    sb.logInfo("%s", inOut)
    widget.setText("maxOut", inOut)
end

function update()
    local heatPercent = world.getObjectParameter(SourceID, "currentEu", 0)
    widget.setProgress("progressBar", heatPercent)
    local processPercent = world.getObjectParameter(SourceID, "process", 0)
    widget.setProgress("processBar", processPercent)
end
function buttonCall()
    player.interact("ScriptPane", "/interface/scripted/reagentlist/reagentlist.ui", SourceID)
end



