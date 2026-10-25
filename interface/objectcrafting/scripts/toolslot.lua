require "/scripts/gui/util.lua"
local oldinit = init
local oldupdate = update

function init()
    if oldinit ~= nil then
        oldinit()
    end
    SourceID = pane.containerEntityId()

    toolslots = world.getObjectParameter(SourceID, "toolslot")
    tool = world.getObjectParameter(SourceID, "tool")
end

function update()
    if oldupdate ~= nil then
        oldupdate()
    end

    toolconfig()
end

function toolconfig()
    local items = itemsInContainerRange(SourceID, toolslots[1], toolslots[2])
    local count = 0

    for o = toolslots[1], toolslots[2] do
        count = count + 1
        widget.setProgress("durabilityBar" .. count, 0)
    end

    for i, item in pairs(items) do
        if item then
            local iConf = root.itemConfig(item).config
            if checktool(iConf.tool, tool) then
                local durability = iConf.durability - (item.parameters.durabilityHit or 0)
                local progress = durability / iConf.durability
                widget.setProgress("durabilityBar" .. i, progress)
            end
        end
    end
end

function checktool(config, tool)
    for _, name in pairs(tool) do
        if config == name then
            return true
        end
    end
end

function reagentconfig()
    local fuelName = world.getObjectParameter(SourceID, "fuelName")
    local fuel = world.getObjectParameter(SourceID, "fuelStorage", 0)
    local fuelmax = world.getObjectParameter(SourceID, "fuelMax", 0)

    widget.setProgress("fuelBar", fuel / fuelmax)
    widget.setText("lblname", fuel)
end

function fuel()
    player.interact("ScriptPane", "/interface/scripted/reagentlist/reagentlist.ui", SourceID)
end
