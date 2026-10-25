require "/scripts/util.lua"
require "/scripts/interp.lua"
fuel = {}

function fuel.init(config)
    storage.fuel = storage.fuel or {}
    storage.fuelStorage = storage.fuelStorage or fuel.createFuelStorage(config)
end

function createFuelStorage(config)
    local arr = {}
    for i, param in pairs(config) do
        arr[i] = {param.type, param.maxFuelCount, 0, param.item}
    end
    return arr
end
