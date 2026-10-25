require "/scripts/util.lua"
require "/scripts/interp.lua"

local sourceID

function init()
    sourceID = pane.sourceEntity()
    reloadlist = true

    createItemList()

    log("", status.statusProperty("exchangelist", {}))
end

function update()
    itemlist(reloadlist)
    reloadlist = false
end

function itemlist()
    if reloadlist then
        local exchangelist = status.statusProperty("exchangelist", {})
        for i, config in pairs(exchangelist) do

        end
    end
end

function log(text, l)
    return sb.logInfo("%s" .. text, l)
end

function createItemList()
    local exchangelist = status.statusProperty("exchangelist", {})
    local id = world.getObjectParameter(sourceID, "id")
    if exchangelist[id] == nil then
        local newItem = {}
        local arr = {}
        for cycles = 1, 6 do
            local input = {}
            local quality = 0
            for i, config in pairs(root.createTreasure(id .. ".requestitems", 1)) do
                local newInput = {
                    name = config.name,
                    count = config.count
                }
                quality = quality + config.parameters.quality
                table.insert(input, newInput)
            end

            local outputItem = root.createTreasure(id .. ".giveitems", rarity(quality)[2])
            local outputCurrency = root.createTreasure(id .. ".givecurrency", rarity(quality)[2])

            local item = {
                input = input,
                output = outputItem,
                currency = outputCurrency
            }
            table.insert(arr, item)
        end
        exchangelist[id] = arr
        status.setStatusProperty("exchangelist", exchangelist)
    end
end

function rarity(quality)
    if quality > 0 and quality < 9 then
        return {"common", 1}
    elseif quality >= 9 and quality < 12 then
        return {"uncommon", 2}
    elseif quality >= 15 and quality < 18 then
        return {"rare", 3}
    elseif quality >= 18 and quality < 21 then
        return {"legendary", 4}
    elseif quality >= 24 and quality < 27 then
        return {"essential", 5}
    elseif quality >= 30 then
        return {"absolute", 6}
    end
end
