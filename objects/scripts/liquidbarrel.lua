require "/scripts/util.lua"

oldInit = init
oldUpdate = update
oldDie = die

function init()
    id = entity.id()
    barrelSpace = config.getParameter("barrelSpace", 10000)

    storage.barrel = storage.barrel or {}
    storage.barrel.liquid = storage.barrel.liquid or config.getParameter("liquid", {"none", 0, ""})

    storage.barrel.save = storage.barrel.save or true
    storage.barrel.flow = storage.barrel.flow or false

    animationSetCount(storage.barrel.liquid[2])
    animationSetColor(storage.barrel.liquid[1])

    message.setHandler(
        "flow",
        function(_, _, stat)
            storage.barrel.flow = stat
            object.setConfigParameter("flow", storage.barrel.flow)
        end
    )
    message.setHandler(
        "save",
        function(_, _, stat)
            storage.barrel.save = stat
            object.setConfigParameter("save", storage.barrel.save)
        end
    )
    message.setHandler(
        "pour",
        function(_, _, stat)
            pourout()
        end
    )
end

function update(...)
    local input = world.containerItemAt(id, 0)
    local output = world.containerItemAt(id, 1)
    local consume = config.getParameter("consumption", 100)
    local add = config.getParameter("adding", 100)

    if input then
        if storage.barrel.liquid[1] == "none" and liquidCheck(input.name) then
            setLiquid(input.name)
        end

        if input.name == storage.barrel.liquid[1] and storage.barrel.liquid[2] < barrelSpace then
            if consume > input.count then
                consume = input.count
            end
            consume = liquitMath(storage.barrel.liquid[2], consume)
            world.containerConsumeAt(id, 0, consume)
            storage.barrel.liquid[2] = storage.barrel.liquid[2] + consume
        end
        animationSetCount()
    end

    if storage.barrel.liquid[1] and storage.barrel.liquid[2] > 0 and storage.barrel.flow then
        if output then
            if storage.barrel.liquid[1] == output.name then
                addLiquidCount = countSpace(output.count, 100)
                world.containerPutItemsAt(id, {name = storage.barrel.liquid[1], count = addLiquidCount}, 1)
                storage.barrel.liquid[2] = storage.barrel.liquid[2] - addLiquidCount
            end
        else
            addLiquidCount = countSpace(0, 100)
            log(addLiquidCount)
            world.containerPutItemsAt(id, {name = storage.barrel.liquid[1], count = addLiquidCount}, 1)
            storage.barrel.liquid[2] = storage.barrel.liquid[2] - addLiquidCount
        end
        animationSetCount()
    end
    animationSetColor()

    object.setConfigParameter("save", storage.barrel.save)
    object.setConfigParameter("flow", storage.barrel.flow)
    object.setConfigParameter("liquid", storage.barrel.liquid)
end

function availableliquids(liquid, liquids)
    for _, v in pairs(liquids) do
        if liquid == v then
            return true
        end
    end
    return false
end

function countSpace(count, add)
    if add + count > 1000 then
        local i = (add + count) - 1000
        add = add - i
    end
    if add > storage.barrel.liquid[2] then
        local i = add - storage.barrel.liquid[2]
        add = add - i
    end
    return add
end

function animationSetColor()
    animator.setPartTag("fullbright", "liquid", liquidColor(storage.barrel.liquid[1]))
end

function animationSetCount()
    animator.setPartTag("fullbright", "size", liquidCount(storage.barrel.liquid[2], barrelSpace))
end

function liquitMath(a, count)
    if count + a > barrelSpace then
        local newCount = (count + a) - barrelSpace
        return count - newCount
    end
    return count
end

function liquidColor(liquid)
    local color = root.assetJson("/configs/liquidColors.config")[liquid]
    local paletteSwaps = ""
    for k, v in pairs(color) do
        paletteSwaps = string.format("%s?replace=%s=%s", paletteSwaps, k, v)
    end
    return paletteSwaps
end

function liquidCount(count, storage)
    local rect = config.getParameter("indicatorRect", {0, 0, 0, 0})
    local size = count / storage
    return string.format("?crop=%s;%s;%s;%s", rect[1], rect[2], rect[3], rect[4] * size)
end

function log(log, text)
    sb.logInfo("%s - - -  %s", log, text)
end

function liquidCheck(liquid)
    for k, _ in pairs(root.assetJson("/configs/liquidColors.config")) do
        if liquid == k then
            return true
        end
    end
    return false
end

function pourout()
    if storage.barrel.liquid[1] ~= "none" then
        local count = 1000
        repeat
            if storage.barrel.liquid[2] < count then
                count = storage.barrel.liquid[2]
            end
            world.spawnItem(storage.barrel.liquid[1], object.position(), count)
            storage.barrel.liquid[2] = storage.barrel.liquid[2] - count
        until storage.barrel.liquid[2] == 0
        storage.barrel.liquid[1] = "none"
        object.setConfigParameter("liquid", storage.barrel.liquid)

        animationSetCount()
        animationSetColor()
    end
end

function setLiquidCount(count)
    storage.barrel.liquid[2] = count
    animationSetCount()
end

function setLiquid(liquid)
    storage.barrel.liquid[1] = liquid
end

function die()
    if oldDie ~= nil then
        oldDie()
    end
    local config = root.itemConfig(object.name()).config

    if storage.barrel.save and storage.barrel.liquid[1] ~= "none" then
        config.liquid = storage.barrel.liquid
        config.description = config.description .. "\n ^green;" .. description()
        config.inventoryIcon =
            config.inventoryIcon ..
            "?replace;000=" .. root.assetJson("/configs/liquidColors.config")[storage.barrel.liquid[1]].E0975C
        world.spawnItem(object.name(), object.position(), 1, config)
    else
        world.spawnItem(object.name(), object.position(), 1)
        pourout()
    end
end

function description()
    return root.itemConfig(storage.barrel.liquid[1]).config.shortdescription .. " ^cyan;" .. storage.barrel.liquid[2]
end
