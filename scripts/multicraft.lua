require "/scripts/multicraft/containerutil.lua"
require "/scripts/multicraft/util.lua"
require "/scripts/multicraft/itemUtil.lua"

require "/scripts/energy/euCore.lua"

function init()
    self.objectConfig = config.getParameter("objectConfig", nil)
    self.energy = config.getParameter("euConfig", nil)

    self.recipes = root.assetJson(self.objectConfig.recipefile)
    self.input = self.objectConfig.input
    self.output = self.objectConfig.output
    self.clockMax = self.objectConfig.clockMax or 10000
    self.killStorage = self.objectConfig.killStorage or false
    self.drop = self.objectConfig.drop or 1
    self.delay = self.objectConfig.delay or 1

    storage.level = storage.level or 1
    storage.clock = storage.clock or 10
    storage.timer = storage.timer or world.time()

    storage.recipes = storage.recipes or self.recipes.recipe
    storage.modules = storage.modules or {}

    storage.efficiency = storage.efficiency or 0
    storage.acceleration = storage.acceleration or 1 + (self.objectConfig.acceleration or 0)
    itemCount = 0

    object.setConfigParameter("acceleration", storage.acceleration)
    object.setConfigParameter("efficiency", storage.efficiency)
    object.setConfigParameter("storageClockMax", world.time())
    object.setConfigParameter("recipes", self.recipes)
    object.setConfigParameter("loadedrecipe", storage.recipes)
    object.setConfigParameter("moduleTable", storage.modules)
    object.setConfigParameter("level", storage.level)

    message.setHandler("modules", updateModuleTable)
    message.setHandler("load", loadRecipes)
    message.setHandler("recipe", recipe)

    if self.energy then
        euCore.init(self.energy)
        euCore.setCurrentEu(config.getParameter("energy", storage.currentEu or 0))
    end

    trigger()
end

function recipe(messageType, isLocal, recipeTable)
    storage.recipes = recipeTable
    sb.logWarn("object : " .. world.entityName(entity.id()) .. ", id : " .. entity.id() .. " [recipe added]")
end

function update(dt)
    if self.energy then
        euCore.update(dt)
    end

    if self.objectConfig.reagent then
        if world.containerItemAt(entity.id(), self.objectConfig.reagent.slot - 1) and storage.reagent.curCount < storage.reagent.maxCount then
            Zcontainer.consumeReagentAt(self.objectConfig.reagent, storage.reagent)
            object.setConfigParameter("reagent", storage.reagent)
        end
    end

    if storage.overflow ~= false then
        animator.setAnimationState("activeState", "active")
    else
        animator.setAnimationState("activeState", "idle")
    end

    object.setConfigParameter("storageClock", storage.clock)
    if self.trigger == true and storage.active ~= true then
        animator.setAnimationState("activeState", "idle")
        return
    end

    storage.clock = (storage.clock + ((world.time() - (storage.timer or 0)) * storage.acceleration)) % world.time()
    storage.timer = world.time()

    self.timer = world.time()
    if storage.wait ~= nil then
        if storage.wait <= storage.clock then
            storage.overflow = Zcontainer.tryAdd(storage.overflow)
            storage.wait = nil
            object.setConfigParameter("storageWait", -1)
            object.setConfigParameter("storageMin", -1)

        --storage.active = false
        end
        return
    end
    --sb.logInfo("Next")
    storage.overflow = Zcontainer.tryAdd(storage.overflow)
    if type(storage.overflow) == "nil" or next(storage.overflow) == nil then
        local stack = world.containerItems(entity.id())
        for _, value in pairs(storage.recipes) do
            storage.overflow = consumeItems(value.input, value.output, value.delay or self.delay, stack, value.level)
            if storage.overflow ~= false then
                goto updateEnd
            end
        end
        storage.active = false
        ::updateEnd::
    else
        storage.active = false
    end
end

function consumeItems(items, prod, delay, stack, level)
    if self.energy and not euCore.canFullyConsumeEu(self.energy.euConsume) then
        return false
    end

    if items == nil then
        return false
    end
    local item2 = {}
    for _, item in pairs(items) do
        if true then
            local counts = 0
            for i = self.input[1], self.input[2] do
                if type(item.name) == "table" then
                    for _, val in pairs(item.name) do
                        local obj = Zutil.deepcopy(item)
                        obj.names, obj.name = nil, val
                        if root.itemDescriptorsMatch(stack[i], obj) then
                            counts = counts + stack[i].count
                            table.insert(item2, obj)
                            if item.count <= counts then
                                goto skip
                            end
                        end
                    end
                elseif root.itemDescriptorsMatch(stack[i], item) then
                    counts = counts + stack[i].count
                    if item.count <= counts then
                        goto skip
                    end
                end
            end
            return false
        end
        ::skip::
    end
    return tail(items, item2, prod, delay)
end

function tail(items, item2, prod, delay)
    if self.energy then
        euCore.consumeEu((self.energy.euConsume))
    end
    local function loop(items)
        for _, item in pairs(items) do
            if type(item.damage) == "number" then
                Zitem.damage(item)
            elseif item.consume ~= false then
                Zcontainer.consumeAt(item, self.input, itemCount)
            end
        end
    end
    loop(items)
    loop(item2)
    prod = Zcontainer.itempool(prod, self.recipes.pool)
    if delayKey(delay) then
        return prod
    end
    return Zcontainer.addItems(prod)
end

function delayKey(delay)
    if delay ~= nil and delay ~= 0 then
        storage.wait = (storage.clock + delay) % world.time()
        object.setConfigParameter("storageWait", storage.wait)
        object.setConfigParameter("storageMin", storage.clock)
        return true
    end
end

function loadRecipes(messageType, isLocal, arr)
    storage.recipes = arr

    object.setConfigParameter("loadedrecipe", storage.recipes)
end

function updateModuleTable(messageType, isLocal, storageModule)
    storage.modules = storageModule

    local energy = 1
    local level = 1

    local acceleration = 0
    local efficiency = 0
    local battary = 0

    for _, item in pairs(storage.modules) do
        local param = root.itemConfig(item).config.moduleparameter

        level = level + (param.level or 0)
        acceleration = acceleration + (param.acceleration or 0)
        efficiency = efficiency + (param.efficiency or 0)
    end

    storage.level = level
    storage.acceleration = acceleration
    storage.efficiency = efficiency

    object.setConfigParameter("level", storage.level)
    object.setConfigParameter("acceleration", storage.acceleration)
    object.setConfigParameter("efficiency", storage.efficiency)

    object.setConfigParameter("storageModule", storage.modules)
end

function dcount(recipes)
    local count = 0
    for _ in pairs(recipes) do
        count = count + 1
    end
    return count
end

function die()
    local storage = storage
    local self = self
    local poz = entity.position()

    if self.killStorage or (type(storage.wait) == "number" and storage.wait ~= 0) then
        if self.drop == "none" or self.drop == 0 then
            return
        elseif type(self.drop) == "number" and type(storage.overflow) == "table" then
            if self.drop > 0 then
                for _, item in pairs(storage.overflow) do
                    world.spawnItem(item.name, poz, math.ceil(item.count))
                end
            else
                for _, item in pairs(storage.overflow) do
                    world.spawnItem(item.name, poz, math.floor(item.count))
                end
            end
        end
    end
end

function trigger()
    message.setHandler(
        "trigger",
        function(_, _, params)
            storage.active = true
        end
    )
    self.trigger = true
end
