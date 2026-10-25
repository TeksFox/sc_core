require "/scripts/interp.lua"

require "/interface/scripted/colorgui/colorizer_objectRoot.lua"
require "/interface/scripted/colorgui/colorizer_tooltipPreviev.lua"

function init()
    playerColorizer = player.getProperty("playerColorizer", nil)
    --playerColorizer = nil
    if playerColorizer == nil then
        setDefaultConfig()
    end

    objectList = "objectListlayout.scroll.list"
    objectSelected = nil
    objects = {}

    colors = root.assetJson("/configs/palettes/colorizer.config")
    currColors = {}
    colorList = "colorizerListlayout.scroll.list"

    partlist = "selectObjectlayout.partlist"
    statList = "selectObjectlayout.statList"
    currList = "selectObjectlayout.currList"
    presList = "presetlayout.scroll.list"

    partData = {}
    stateData = {}
    currData = {}
    presetData = {}

    forceReset = true

    selectColorCategory = widget.getSelectedData("colorCategory").option

    checkList = {}
    tooltipPrevievList = {}

    parameters = nil

    widget.registerMemberCallback(partlist, "selectPart", selectPart)
    widget.registerMemberCallback(statList, "statPart", statPart)
    widget.registerMemberCallback(currList, "colorSelect", colorSelect)
    widget.registerMemberCallback(colorList, "setColor", setColor)

    widget.registerMemberCallback(presList, "usePreset", usePreset)

    canvas = widget.bindCanvas("selectObjectlayout.canvas")
    sphereCanvas = widget.bindCanvas("selectObjectlayout.sphereCanvas")

    widget.setButtonEnabled("presetlayout.savePreset", false)
    widget.setVisible("objectListlayout", true)

    for _, wName in pairs(config.getParameter("sliderOptions")) do
        local option = widget.getData(wName).option
        widget.setChecked(wName, playerColorizer.sliderOption[option])
    end

    availableObjects(objectListCteate())
    availableColors()
    buttonCategory()
end

function options(widgetName)
    local option = widget.getData(widgetName).option
    playerColorizer.sliderOption[option] = widget.getChecked(widgetName)
    player.setProperty("playerColorizer", playerColorizer)
end

function update()
    if objectSelected and world.entityExists(objectSelected.id) then
        unpackObject(objectSelected, canvas, partData)
    end

    if not objectSelected or not world.entityExists(objectSelected.id) then
        widget.clearListItems(currList)
        widget.clearListItems(statList)
        widget.clearListItems(partlist)
        canvas:clear()
        sphereCanvas:clear()
    end

    if objectSelected and world.getObjectParameter(objectSelected.id, "objectName") == objectSelected.name then
        widget.setButtonEnabled("presetlayout.savePreset", true)
        widget.setOptionEnabled("buttonCategory", 3, true)
    else
        widget.setOptionEnabled("buttonCategory", 3, false)
    end
end

function createTooltip(screenPosition)
    for wName, data in pairs(tooltipPrevievList) do
        if widget.inMember(wName, screenPosition) and widget.active("presetlayout") then
            return tooltip.create(data)
        end
    end
end

function pCreateCategiry()
    if playerColorizer.savedPalette[objectSelected.name] then
    end
end

function availableObjects(objects)
    widget.clearListItems(objectList)
    for _, object in pairs(objects) do
        local list = string.format("%s.%s", objectList, widget.addListItem(objectList))

        widget.setItemSlotItem(list .. ".icon", object.name)
        widget.setText(list .. ".name", string.format("%s - [%s]", root.itemConfig(object.name).config.shortdescription, object.id))

        widget.setData(list, object)
    end
end

function colorCategory()
    local data = widget.getSelectedData("colorCategory").option
    if selectColorCategory ~= data then
        selectColorCategory = data
        availableColors()
    end
end

function availableColors()
    widget.clearListItems(colorList)

    for i, color in pairs(colors.colors) do
        local filter = true
        if filter then
            filter = selectColorCategory == color.group or selectColorCategory == "all"
        end
        if not color.hide and filter then
            local list = string.format("%s.%s", colorList, widget.addListItem(colorList))

            --widget.setVisible(list .. ".locker", false)
            widget.setButtonEnabled(list .. ".selector", false)
            widget.setImage(list .. ".image", "/interface/scripted/colorgui/paletter.png:2" .. pickColor(i))
            if color.unlock or player.isAdmin() then
                widget.setButtonEnabled(list .. ".selector", true)
                widget.setImage(list .. ".image", "/interface/scripted/colorgui/paletter.png:1" .. pickColor(i))
                widget.setVisible(list .. ".locker", false)
            end
            widget.setData(list, {name = i, color = color})
        end
    end
end
--Выбираем Объект
function objectSelect()
    updateObject()
    widget.clearListItems(currList)
    widget.clearListItems(statList)
    widget.clearListItems(partlist)
    if objectSelected ~= nil and world.entityExists(objectSelected.id) then
        sphereCanvas:clear()
        objectParameters(objectSelected)
        unpackObject(objectSelected, canvas)
        createPresetList(player.getProperty("playerColorizer", nil))
    end
    clearData()
end

function createPresetList(conf)
    widget.clearListItems(presList)
    if conf.savedPalette[objectSelected.name] ~= nil then
        for i, config in pairs(conf.savedPalette[objectSelected.name]) do
            local listWidget = widget.addListItem(presList)
            local list = string.format("%s.%s", presList, listWidget)

            widget.setText(list .. ".name", i)

            widget.setData(list, {config = config, index = i})
            tooltipPrevievList[string.format("%s.%s", presList, listWidget)] = config
        end
    end
end

function setName()
    return widget.getText("presetlayout.setName")
end

function savePreset()
    local conf = player.getProperty("playerColorizer", nil)
    local string = {}
    local number = "^green; [" .. tostring(math.random(0, 9999)) .. "]"
    if objectSelected and world.entityExists(objectSelected.id) and parameters ~= nil then
        if conf.savedPalette[objectSelected.name] == nil then
            conf.savedPalette[objectSelected.name] = {}
        end
        conf.savedPalette[objectSelected.name][widget.getText("presetlayout.setName") .. number] = parameters

        player.setProperty("playerColorizer", conf)
        createPresetList(conf)
    end
end

function usePreset(widgetName)
    presetData = dataReplacer(presetData, listDataExtract(presList))
    if presetData then
        if widgetName == "selectPreset" then
            if objectSelected ~= nil and world.entityExists(objectSelected.id) then
                world.sendEntityMessage(objectSelected.id, "colorizerReplace", presetData.config)
                unpackObject(objectSelected, canvas)
                objectSelect()
                parameters = presetData.config
            end
        end
        if widgetName == "removePreset" then
            local conf = player.getProperty("playerColorizer", nil)
            conf.savedPalette[objectSelected.name][presetData.index] = nil
            player.setProperty("playerColorizer", conf)
            createPresetList(conf)
        end
    end
end

function updateObject()
    local list = widget.getListSelected(objectList)
    objectSelected = list and widget.getData(string.format("%s.%s", objectList, list)) or nil
end

--Выгружаем содержимое части
function objectParameters(object)
    widget.clearListItems(partlist)
    widget.clearListItems(statList)
    widget.clearListItems(currList)

    if objectSelected and world.entityExists(objectSelected.id) then
        world.spawnProjectile("selectArrow", positionCalcul(objectSelected.id), objectSelected.id, {0, 0}, false)

        parameters = getParameter(objectSelected.id, "colorizerParameter").animationParts

        for i, _ in pairs(parameters) do
            if not parameters[i].hide then
                local list = string.format("%s.%s", partlist, widget.addListItem(partlist))
                widget.setText(list .. ".button", i)

                widget.setData(list, {name = i})
            end
        end
    end
    clearData()
end

function positionCalcul(id)
    local objSpace = objectSpaces(id)
    local pos = world.entityPosition(id)
    return {pos[1] + (objSpace[1] / 2), pos[2] + objSpace[2]}
end

function objectSpaces(id)
    local spaces = world.objectSpaces(id)
    local arr = {}
    for i = 1, 2 do
        local firstArr = {}

        for _, num in pairs(spaces) do
            table.insert(firstArr, num[i])
        end
        local int = sorter(firstArr)
        table.insert(arr, int)
    end
    return arr
end

function sorter(arr)
    table.sort(
        arr,
        function(a, b)
            return (a > b)
        end
    )
    return arr[1]
end

--Выгружаем состояние
function selectPart()
    partData = dataReplacer(partData, listDataExtract(partlist))
    sphereCanvas:clear()
    checkList = {}
    stateData = {}

    if next(partData) then
        widget.clearListItems(statList)
        widget.clearListItems(currList)
        for stat, _ in pairs(parameters[partData.name].colors) do
            local listWidget = widget.addListItem(statList)
            local list = string.format("%s.%s", statList, listWidget)
            widget.setText(list .. ".button", stat)

            widget.setData(list, {stat = stat, name = partData.name})
        end

        unpackObject(objectSelected, canvas, partData)
    end

    currData = {}
end
--Выгружаем палитру
function statPart()
    stateData = dataReplacer(stateData, listDataExtract(statList))
    sphereCanvas:clear()
    checkList = {}
    if next(stateData) then
        widget.clearListItems(currList)
        for i, color in pairs(parameters[stateData.name].colors[stateData.stat]) do
            local listWidget = widget.addListItem(currList)
            local list = string.format("%s.%s", currList, listWidget)

            widget.setData(
                list,
                {
                    stat = stateData.stat,
                    name = stateData.name,
                    color = color
                }
            )
            table.insert(checkList, currList .. "." .. listWidget)

            sphereCanvasDraw(parameters[stateData.name].colors[stateData.stat])
        end
    end
end

function pickColor(color)
    local palette = ""
    local default = {"FFCA8A", "E0975C", "A85636", "6F2919"}
    local color = colors.colors[color].palette
    local paletteSwaps = ""
    for i, v in pairs(color) do
        paletteSwaps = string.format("%s?replace=%s=%s", paletteSwaps, default[i], v)
    end
    return paletteSwaps
end

function colorSelect(widgetName)
    currData = dataReplacer(currData, listDataExtract(currList))
    widget.setSelectedOption("buttonCategory", 2)
end

function setColor()
    if next(currData) then
        local colordata = listDataExtract(colorList) or nil

        for i, _ in pairs(parameters[currData.name].colors[currData.stat]) do
            if next(checkList) and widget.getChecked(checkList[i] .. ".colorSelect") then
                parameters[currData.name].colors[currData.stat][i] = colordata.name
            end
        end

        sphereCanvasDraw(parameters[stateData.name].colors[stateData.stat])
        colorReplacer(objectSelected, canvas, parameters)
        unpackObject(objectSelected, canvas, stateData.name)
    end
end

function dataReplacer(oldData, newData)
    if oldData ~= newData or oldData == nil and replace then
        oldData = newData
    end
    return oldData
end

function colorReplacer(object, canvas, data)
    world.sendEntityMessage(object.id, "colorizerReplace", parameters)
end

function buttonCategory()
    local data = widget.getSelectedData("buttonCategory")
    if data.option == "objects" then
        hideAll()
        widget.setVisible("objectListlayout", true)
    elseif data.option == "colors" then
        hideAll()
        widget.setVisible("colorizerListlayout", true)
    elseif data.option == "preset" then
        hideAll()
        widget.setVisible("presetlayout", true)
        if objectSelected then
            createPresetList(player.getProperty("playerColorizer", nil))
        end
    end
end

function hideAll()
    widget.setVisible("presetlayout", false)
    widget.setVisible("colorizerListlayout", false)
    widget.setVisible("objectListlayout", false)
end

function setName()
    local name = widget.getText("palettelayout.setName") or "unnamed"
    return name
end

function toggleswitchoption(option)
    if option then
        widget.setVisible("palettelayout", false)
        widget.setVisible("collectionlayout", true)
    else
        widget.setVisible("collectionlayout", false)
        widget.setVisible("palettelayout", true)
    end
end

function objectListCteate()
    local arr = {}
    local IDs = world.objectQuery(world.entityPosition(player.id()), 100)
    for _, object in pairs(IDs) do
        if world.getObjectParameter(object, "colorizer") ~= nil then
            table.insert(
                arr,
                {
                    position = world.entityPosition(object),
                    id = object,
                    name = world.getObjectParameter(object, "objectName")
                }
            )
        end
    end
    return arr
end

function setDefaultConfig()
    player.setProperty("playerColorizer", root.assetJson("/configs/main.config").playerColorizer)

    playerColorizer = player.getProperty("playerColorizer", nil)
end

function listDataExtract(list)
    return widget.getData(string.format("%s.%s", list, widget.getListSelected(list))) or nil
end

function getParameter(id, parameter)
    return world.getObjectParameter(id, parameter)
end

function clearData()
    partData = {}
    stateData = {}
    currData = {}
    colordata = {}

    sphereCanvas:clear()
    checkList = {}
end
