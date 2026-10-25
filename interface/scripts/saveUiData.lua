saveUiData = {}

function saveUiData.load(dataName, ui)
    local config = saveUiData.check(dataName, ui)
    saveUiData.apply(config)
end

function saveUiData.check(dataName, ui)
    local playerData = player.getProperty(dataName)
    if not playerData then
        local data = {}
        player.setProperty(dataName, data)
    end
    if not playerData[ui] then
        local playerData = player.getProperty(dataName)
        local data = {}
        data[ui] = {}
        player.setProperty(dataName, data)
    end
    return player.getProperty(dataName)
end

function saveUiData.save(dataName, data, type, widgetName, ui)
    local playerData = saveUiData.check(dataName, ui)
    playerData[ui] = {type = type, bool = data, name = widgetName}
    player.setProperty(dataName, playerData)
end

function saveUiData.apply(config)
    if config and next(config) then
        for i, data in pairs(config) do
            widget.setChecked(data.name, data.bool)
        end
    end
end
