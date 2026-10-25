calk = {}
function calk.accuracy(name, point, config)
    if name == "accuracy" then
        return math.floor(point + (config.stats.perception / 3))
    end
    if name == "health" then
        return math.floor(point + (config.stats.strength))
    end
    return point
end

function calk.playerHealth(pl)
    return pl.stats.health + pl.stats.strength
end
