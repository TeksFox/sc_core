require "/scripts/gui/util.lua"

local oldupdate = update

function update()
    if oldupdate ~= nil then
        oldupdate()
    end

    reagentconfig()
end

function reagentconfig()
    local id = pane.containerEntityId()
    local cur = world.getObjectParameter(id, "fuelcur", 0)
    local max = world.getObjectParameter(id, "fuelMax", 0)
    widget.setProgress("fuelBar", cur / max)
end
