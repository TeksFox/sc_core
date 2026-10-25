oldInit = init
oldUpdate = update

function init()
    if oldInit then
        oldInit()
    end
    reagent = config.getParameter("reagentConfig", nil)
    reagentItem = root.assetJson("/configs/itemparameters.config").reagents[reagent.type]

    storage.reagent = storage.reagent or {}
    storage.reagent.current = storage.reagent.current or 0
end

function update(dt)
    if oldUpdate then
        oldUpdate(dt)
    end

    local input = reagent.input
    local stack = world.containerItems(entity.id())
    for name, item in pairs(reagentItem) do
        for o = input[1], input[2] do
            if stack[o] ~= nil and root.itemDescriptorsMatch(stack[o].name, name) and stack[o].count >= item[2] then
                reagentConsume(stack, o, item[1], item[2])
            end
        end
    end
end

function reagentConsume(stack, o, weight, count)
    local consume = true
    if storage.reagent.current + weight > reagent.reagentAmount then
        consume = false
    end
    if consume then
        storage.reagent.current = storage.reagent.current + weight
        world.containerConsumeAt(entity.id(), o - 1, count)
    end

    object.setConfigParameter("fuelcur", storage.reagent.current)
end
--Проверка наличия топлива
--Требуемое количество

function reagentCheck()
    if storage.reagent.current >= reagent.reagentConsume then
        return false
    end

    return true
end

function setReagent()
    storage.reagent.current = storage.reagent.current - reagent.reagentConsume

    object.setConfigParameter("fuelcur", storage.reagent.current)
end
