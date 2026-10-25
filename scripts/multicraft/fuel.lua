oldInit = init
oldUpdate = update

function init()
    if oldInit then
        oldInit()
    end
    fuel = config.getParameter("fuelConfig", nil)
    fuelItem = root.assetJson("/configs/itemparameters.config").fuels[fuel.type]

    storage.fuel = storage.fuel or {}

    storage.fuel.amount = storage.fuel.amount or 0
    storage.fuel.current = storage.fuel.current or 0
    storage.fuel.name = storage.fuel.name or "none"
    storage.fuel.active = storage.fuel.active or false
end

function update(dt)
    if storage.overflow and storage.active and getStockFuel() or storage.fuel.active and getStockFuel() then
        storage.fuel.current = storage.fuel.current - fuel.consume * (1 - storage.efficiency or 0)
    end
    
    fuelConsuptionStart()
    if not getStockFuel() then
        storage.fuel.active = false
        storage.active = false
    end
    if oldUpdate then
        oldUpdate(dt)
    end

    object.setConfigParameter("fuel_amount", storage.fuel.amount)
    object.setConfigParameter("fuel_current", storage.fuel.current)

end

function fuelConsuptionStart()
    local input = fuel.input
    local stack = world.containerItems(entity.id())
    if not getStockFuel() then
        for name, item in pairs(fuelItem) do
            for o = input[1], input[2] do
                if stack[o] ~= nil and root.itemDescriptorsMatch(stack[o].name, name) and stack[o].count >= item[2] then
                    fuelConsume(stack, o, item[1], item[2])
                end
            end
        end
    end
end

function fuelConsume(stack, o, weight, count)
    storage.fuel.amount = weight
    storage.fuel.current = storage.fuel.amount
    world.containerConsumeAt(entity.id(), o - 1, count)
end

function getStockFuel()
    return storage.fuel.current > 0
end
