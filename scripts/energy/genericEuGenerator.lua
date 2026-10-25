require "/scripts/energy/euCore.lua"

local euCore = euCore
local euConfig

function init()
    euConfig = config.getParameter("euConfig", "")
    euCore.init(euConfig)

    storage.currfuel = storage.currfuel or 0
    storage.fuelmax = storage.fuelmax or 0
    storage.consume = storage.consume or 0
    
    storage.list = root.assetJson("/configs/reagentParameters.config")[euConfig.reagents]
    object.setConfigParameter("itemList", storage.list)
end

function update(dt)
    euCore.update(dt)
    local contents = world.containerItems(entity.id())
    if storage.currfuel > 0 then
        storage.currfuel = storage.currfuel - storage.consume
        euCore.setCurrentEu(euCore.getCurrentEu() + storage.consume)
        animator.setAnimationState("activeState", "active")
    elseif euCore.getCurrentEu() >= euConfig.euStorage then
        animator.setAnimationState("activeState", "idle")
    else
        animator.setAnimationState("activeState", "idle")
        for i, item in pairs(storage.list) do
            for o = 1, 3 do
                if contents[o] ~= nil and root.itemDescriptorsMatch(contents[o], {name = item.name, count = item.count}) then
                    if contents[o].count >= item.count then
                        world.containerConsumeAt(entity.id(), o - 1, item.count)
                        storage.consume = item.time
                        storage.fuelmax = item.energy
                        storage.currfuel = storage.fuelmax
                        animator.setAnimationState("activeState", "idle")
                    end
                end
            end
        end
    end
    object.setConfigParameter("currfuel", storage.currfuel)
    object.setConfigParameter("fuelmax",  storage.fuelmax)
end
