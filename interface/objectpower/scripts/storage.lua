require "/scripts/util.lua"
local SourceID

function init()
    SourceID = pane.sourceEntity()

    widgets()
end

function update()
    local euEnergy = world.getObjectParameter(SourceID, "currentEu", 0)
    local euConfig = world.getObjectParameter(SourceID, "euConfig")


    widget.setProgress("progressBar", euEnergy)
    widget.setText("euCount", string.format("%s", math.ceil(euEnergy * euConfig.euStorage)))
end
function widgets()
    local object = world.getObjectParameter(SourceID, "objectName")
    local config = root.itemConfig(object)

    local maxInOut = 32 * config.config.euConfig.euLevel
    local inOut = string.format("%s", maxInOut)
    widget.setText("maxInput", inOut)
    widget.setText("maxStorage", config.config.euConfig.euStorage)
end

