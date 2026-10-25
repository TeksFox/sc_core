oldInit = init
oldUpdate = update

function init()
    if oldInit ~= nil then
        oldInit()
    end
    SourceID = pane.containerEntityId()
    widget.setText("name", "Empty")
    widget.setChecked("flow", world.getObjectParameter(SourceID, "flow", false))
    widget.setChecked("save", world.getObjectParameter(SourceID, "save", false))
end

function update()
    if oldUpdate ~= nil then
        oldUpdate()
    end
    local flow = world.getObjectParameter(SourceID, "flow", false)
    local liquid = world.getObjectParameter(SourceID, "liquid", {})
    local maxcount = world.getObjectParameter(SourceID, "barrelSpace", 10000)
    local progress = liquid[2] / maxcount

    if liquid[1] ~= "none" then
        widget.setItemSlotItem("icon", liquid[1])
        widget.setText("name", root.itemConfig(liquid[1]).config.shortdescription)
    else
        widget.setItemSlotItem("icon", "")
        widget.setText("name", "Empty")
    end
    if widget.getData("count") then
        widget.setText("count", string.format("%s", liquid[2], maxcount))
    else
        widget.setText("count", string.format("%s / %s", liquid[2], maxcount))
    end

    widget.setFontColor("flofTitle", flow and "green" or "red")
    widget.setText("flofTitle", string.format("Flow: %s", flow and "Opened" or "Closed"))

    widget.setImage("progressImage", image("progressImage", progress, liquid[1]))
end

function image(name, progress, liquid)
    local data = widget.getData(name)
    return data.file .. liquidColor(liquid) .. liquidCount(progress, data.file, data.direction)
end

function liquidColor(liquid)
    local color = root.assetJson("/configs/liquidColors.config")[liquid or "default"]
    local paletteSwaps = ""
    for k, v in pairs(color) do
        paletteSwaps = string.format("%s?replace=%s=%s", paletteSwaps, k, v)
    end
    return paletteSwaps
end

function liquidCount(progress, file, direction)
    local image = root.nonEmptyRegion(file)
    if direction == "horizontal" then
        return string.format("?crop=%s;%s;%s;%s", image[1], image[2], image[3] * progress, image[4])
    else
        return string.format("?crop=%s;%s;%s;%s", image[1], image[2], image[3], image[4] * progress)
    end
end

function flow(widgetName)
    world.sendEntityMessage(SourceID, widgetName, widget.getChecked(widgetName))
end

function pourout()
    world.sendEntityMessage(SourceID, "pour")
end
