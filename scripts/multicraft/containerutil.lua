require "/scripts/multicraft/util.lua"
require "/scripts/util.lua"
Zcontainer = {}

function Zcontainer.tryAdd(items)
    if type(items) == "table" and next(items) ~= nil then
        return Zcontainer.addItems(items)
    end
end

function Zcontainer.addItems(items)
    local id, arr = entity.id(), {}
    for _, item in pairs(items) do
        local t = Zcontainer.putAt(item, self.output)
        if type(t) == "table" then
            table.insert(arr, t)
        end
    end
    return arr
end

function Zcontainer.itempool(orig, pool)
    items = Zutil.deepcopy(orig)
    local arr = {}
    for key, item in pairs(items) do
        if type(item.count) == "table" then
            item.count = util.randomIntInRange(item.count)
        end

        if item.name and not item.chance then
            table.insert(arr, item)
        else
            if item.chance and math.random() <= item.chance then
                table.insert(arr, item)
            end
        end
        if item.pool then
            arr = Zcontainer.addPool(pool, item.pool, arr, item.weight)
        end
    end
    return arr
end

function Zcontainer.addPool(pool, name, arr, weight)
    for c, item in pairs(pool[name]) do
        local count = 0
        if math.random() <= item[1] then
            if type(item[2][2]) == "table" then
                count = util.randomIntInRange(item[2][2])
            else
                count = item[2][2]
            end
            table.insert(arr, {name = item[2][1], count = count})
        end
    end

    return arr
end

function Zcontainer.consumeReagentAt(param, item)
    local ragent = root.assetJson("/configs/reagentconfig/" .. param.name .. ".config").config
    local id = entity.id()
    local stack = world.containerItemAt(id, param.slot - 1)
    local slotItem = ragent[stack.name] or nil
    --
    if slotItem ~= nil then
        sb.logInfo("%s     %s", slotItem[2], item.maxCount - item.curCount)
        if item.maxCount - item.curCount >= slotItem[2]  then
            if item.name == "none" then
                item.name = stack.name
                world.containerConsumeAt(id, param.slot - 1, slotItem[1])
                item.curCount = item.curCount + slotItem[2]
            elseif item.name == stack.name then
                world.containerConsumeAt(id, param.slot - 1, slotItem[1])
                item.curCount = item.curCount + slotItem[2]
            end
        end
    end
    storage.reagent = item
end

function Zcontainer.consumeAt(item, range)
    if type(item.name) == "table" then
        return
    end

    storage.count = storage.count or 0
    local id = entity.id()
    local stack = world.containerItems(id)
    local itemCount = item.count
    for o = range[1], range[2] do
        if stack[o] ~= nil and root.itemDescriptorsMatch(stack[o], item) then
            --проверяем наличие остатков если используется, параметер storage.count равен нулю
            if stack[o].count >= itemCount and storage.count ~= 0 then
                world.containerConsumeAt(id, o - 1, storage.count)
                storage.count = 0
                return true
            end
            --если все как надо просто отнимаем количество
            if stack[o].count >= itemCount then
                world.containerConsumeAt(id, o - 1, itemCount)
                return true
            else
                storage.count = itemCount - stack[o].count
                world.containerTakeAt(id, o - 1)
            end
        end
    end
end

function Zcontainer.putAt(item, range)
    local id = entity.id()
    local stack = world.containerItems(id)
    for o = range[1], range[2] do
        if stack[o] == nil or root.itemDescriptorsMatch(stack[o], item) then
            item = world.containerPutItemsAt(id, item, o - 1)
            if item == nil or next(item) == nil or item.count <= 0 then
                return true
            end
        end
    end
    return item
end

function Zcontainer.occupied(range)
    local stacks = world.containerItems(entity.id())
    for o = self.output[1], self.output[2] do
        if stacks[o] ~= nil then
            return true
        end
    end
end
