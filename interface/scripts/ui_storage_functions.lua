require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/utils/ui_utils.lua"
ps = {}

function ps.check()
    widget.setChecked("btnPersonalStorageEnabler", ps.getEnabled())
end

function ps.consumeItem(name, count)
    local list = ps.getItems()
    list[name].count = list[name].count - count
    player.setProperty("personalstorage", list)
end

function ps.giveItem(name, count)
    local list = ps.getItems()
    if list[name] then
        list[name].count = list[name].count + count
    else
        list[name] = {name = name, count = count, category = root.itemConfig(name).config.category}
    end

    player.setProperty("personalstorage", list)
end

function ps.hasCountOfItem(name)
    local list = ps.getItems()
    if list[name] then
        return list[name].count
    end

    return 0
end

function ps.getItems()
    return player.getProperty("personalstorage", {})
end

function ps.getEnabled()
    return player.getProperty("storageenabled", false)
end
