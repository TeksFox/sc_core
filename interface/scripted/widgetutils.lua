ui = {}

function ui.getListData(list, data)
    return ui.listData(data, ui.updateListData(list))
end

function ui.updateListData(list)
    return widget.getData(string.format("%s.%s", list, widget.getListSelected(list))) or nil
end

function ui.listData(oldData, newData)
    if oldData ~= newData or oldData == nil and replace then
        oldData = newData
    end
    return oldData
end

function ui.createVisualParameter(parameter, bool, p)
    local text = ""
    if p then
        text = string.gsub(string.format("%s%%", math.floor(parameter * 100)), "-", "")
    else
        text = string.gsub(string.format("%s", parameter), "-", "")
    end

    if parameter > 0 and bool then
        text = "^green;" .. "+ " .. text
    elseif parameter < 0 and bool then
        text = "^red;" .. "- " .. text
    elseif parameter > 0 and not bool then
        text = "^red;" .. "+ " .. text
    elseif parameter < 0 and not bool then
        text = "^green;" .. "- " .. text
    end

    return text
end
