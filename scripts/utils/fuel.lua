fuel = {}
--что то
function fuel.init()
    storage.fuel = storage.fuel or 0
    storage.fuelAmout = storage.fuelAmout or 0
    storage.fuelmode = fuelconfig.fuelmode
end
--Не понимаю но тоже что то подобное
function fuel.update(id, fuelconfig)
    local slots = fuelconfig.fuelslotrange

    if storage.active == true and storage.fuel > 0 or storage.fuelmode == true then
        storage.fuel = storage.fuel - (1 + storage.acceleration)
        storage.active = true
    else
        storage.active = false
    end
    --Проверка топлива
    local acceptablefuel = root.assetJson(fuelconfig.acceptablefuel).config
    local range = fuelconfig.slotrange
    for i, item in pairs(acceptablefuel) do
        if storage.fuel <= 0 and storage.active == true then
            fuel.active(item, range, id, slots)
        end
    end

    object.setConfigParameter("fuelStorage", storage.fuel)
    object.setConfigParameter("fuelMax", storage.fuelAmout)
end
function fuel.active(item, range, id, slots)
    local stack = world.containerItems(id)
    local itemCount = item.count

    for o = slots[1] - 1, slots[2] - 1 do
        if stack[o] ~= nil and root.itemDescriptorsMatch(stack[o], item) then
            if stack[o].count >= itemCount then
                storage.fuelAmout = (12 * item.euGenerated) * item.processingTime
                world.containerConsumeAt(id, o - 1, itemCount)
                storage.fuel = storage.fuelAmout
                return true
            end
        end
    end

    object.setConfigParameter("fuelslots", range)
    return false
end
