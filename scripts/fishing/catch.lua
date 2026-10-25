require "/scripts/util.lua"
catch = {}

function catch.init()
    self.config = root.assetJson("/configs/fishing.config")
end

function catch.timeOfDay()
    local time = world.timeOfDay()
    local day = self.config.daytime
    local night = self.config.nighttime

    if time >= day[1] and time <= day[2] then
        return "day"
    end
    if time >= night[1] and time <= night[2] then
        return "night"
    end
end

function catch.finish()
    return util.randomFromList(catch.builder())
end

function catch.particles(ulow, config)
    local specification = config.body[1].options[1].specification
    specification.image = "/animations/fishingparticle/icon.png:" .. ulow.type
    specification["color"] = self.config.colors[ulow.rarity]
    return config
end

function catch.builder()
    local rarity = util.weightedRandom(self.config.rarity)
    local pool = self.config.pools[world.type()]
    local arr = {}
    for i, item in pairs(pool) do
        if catch.period(item.period) and catch.surface(item.surface) and item.rarity == rarity then
            table.insert(arr, item)
        end
    end
    return arr
end

function catch.worlds()
    local wType = world.type()

    if wType == "unknown" or self.config.pools[world.type()] == nil then
        return false
    else
        return true
    end
end

function catch.surface(item)
    if item and world.inSurfaceLayer(entity.position()) == item then
        return true
    end
    if not item then
        return true
    end
    return false
end

function catch.period(item)
    for _, t in pairs(item) do
        if catch.timeOfDay() == t then
            return true
        end
    end
    return false
end
