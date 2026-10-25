require "/scripts/util.lua"
require "/scripts/interp.lua"

require "/interface/scripts/ui_components.lua"
require "/interface/scripted/itemList/groupList.lua"

function init()
    SourceID = pane.sourceEntity()
    self.energy = world.getObjectParameter(SourceID, "euConfig", nil)
    self.fuel = world.getObjectParameter(SourceID, "fuelConfig", nil)
    self.recipes = world.getObjectParameter(SourceID, "recipes")
    self.objectConfig = world.getObjectParameter(SourceID, "objectConfig")
    self.loadedrecipe = world.getObjectParameter(SourceID, "loadedrecipe", {})

    self.dataSelected = nil
    self.data = nil

    self.itemList = "itemScroll.list"
    self.toolTipList = {}
    self.namesTooltips = {}
    self.curSearch = ""
    self.curFilter = ""
    self.selectedItem = ""
    self.selectCategory = ""
    self.lvlCheck = 1
    self.level = world.getObjectParameter(SourceID, "level", 1)
    self.buttons = {}

    self.forceReload = true

    world.sendEntityMessage(SourceID, "statReload")

    widget.registerMemberCallback(self.itemList, "add", add)
    widget.registerMemberCallback(self.itemList, "remove", add)
    
    ui.init( world.getObjectParameter(SourceID, "objectName"))

    widget.setItemSlotItem("titleicon", world.getObjectParameter(SourceID, "objectName"))
end

function add(widgetName)
    if self.dataSelected then
        self.loadedrecipe = world.getObjectParameter(SourceID, "loadedrecipe", {})

        if widgetName == "add" then
            self.loadedrecipe[self.dataSelected.index] = self.dataSelected.config
        else
            self.loadedrecipe[tostring(self.dataSelected.index)] = nil
        end

        world.sendEntityMessage(SourceID, "load", self.loadedrecipe)
    end
    self.forceReload = true
end

function removeall()
    world.sendEntityMessage(SourceID, "load", {})
    self.loadedrecipe = {}
    self.forceReload = true
end

function update(dt)
    self.level = world.getObjectParameter(SourceID, "level", 1)
    if self.dataSelected then
        widget.setVisible("scroll", true)
    else
        widget.setVisible("scroll", false)
    end
    --upgrade.init(SourceID)
    level()
    search()
    listItem(self.forceReload, dt)
    self.forceReload = false
end

function getText()
    return widget.getText("filter")
end

function search()
    local search = getText()
    if self.curSearch ~= search then
        self.curSearch = search
        self.forceReload = true
    end
end

function level()
    if self.lvlCheck ~= self.level then
        self.lvlCheck = self.level
        self.forceReload = true
    end
    pane.setTitle(
        "^green;Recipe list [ " .. world.getObjectParameter(SourceID, "shortdescription") .. "^green; ]",
        "List of available recipes"
    )
end

function showLevel()
    self.forceReload = true
    return widget.getChecked("showLevel")
end

function createTooltip(screenPosition)
    for wName, data in pairs(self.toolTipList) do
        if widget.inMember(wName, screenPosition) then
            local tooltips = config.getParameter("tooltips")
            tooltips.text.value = (data.friendlyname or "^red;Select tab name!")
            return tooltips
        end
    end
    for _, wName in pairs(self.buttons) do
        if widget.inMember(wName .. ".add", screenPosition) then
            local tooltips = config.getParameter("tooltips")
            tooltips.text.value = widget.getData(wName .. ".add").text
            return tooltips
        end
        if widget.inMember(wName .. ".remove", screenPosition) then
            local tooltips = config.getParameter("tooltips")
            tooltips.text.value = widget.getData(wName .. ".remove").text
            return tooltips
        end
    end
    for wName, input in pairs(self.namesTooltips) do
        if widget.inMember(wName, screenPosition) then
            sb.logInfo("??? %s", input)
            local itemList = config.getParameter("itemList")
            local layout = config.getParameter("layout")

            local listWidget = itemList.listWidgewt
            local position = itemList.listParameter.position
            local size = itemList.listParameter.memberSize
            local spacing = itemList.listParameter.spacing

            listWidget.background.fileBody = itemList.background .. "?scalenearest=1;" .. (1 * ((size[2] + spacing[2]) * #input)) - spacing[2]
            listWidget.title.position = {64, 28 + (1 * ((size[2] + spacing[2]) * #input) - spacing[2])}
            for i, name in pairs(input) do
                if type(name) == "table" then
                    name = name[1]
                end
                local itemConfig = root.itemConfig(name)
                local item = {
                    type = "layout",
                    layoutType = "basic",
                    size = size,
                    position = {position[1], (position[2] + (size[2] + spacing[2]) * (i - 1))},
                    zlevel = 10,
                    children = {}
                }

                item.children.background = copy(layout.itemBackground)
                item.children.itemIconBack = copy(layout.itemIconBack)
                item.children.itemName = copy(layout.itemName)
                item.children.itemName.value = itemConfig.config.shortdescription

                local image = util.absolutePath(itemConfig.directory, itemConfig.config.inventoryIcon)
                item.children.icon = copy(layout.icon)
                item.children.icon.file = util.absolutePath(itemConfig.directory, itemConfig.config.inventoryIcon)

                item.children.itemIconRarityBack = copy(layout.itemIconRarityBack)
                item.children.itemIconRarityBack.file = "/interface/inventory/itemborder" .. string.lower(itemConfig.config.rarity) .. ".png"

                listWidget["item" .. i] = item
            end
            return listWidget
        end
    end
end

function listItem(forceReload, dt)
    if forceReload then
        widget.clearListItems(self.itemList)
        for i, config in pairs(self.recipes.recipe) do
            local name = config.name or config.output[1].name

            local filter = true
            if filter then
                filter = categoryCheck(config.groups) == true
            end

            if showLevel() then
                if filter then
                    filter = config.level <= self.level
                end
            end
            if filter and (self.curSearch ~= "") then
                filter = (string.find(root.itemConfig(name).config.shortdescription:lower(), self.curSearch) ~= nil)
            end
            --*
            if filter then
                local listWidget = widget.addListItem(self.itemList)
                local itemList = string.format("%s.%s", self.itemList, listWidget)
                local recipeLevel = self.level + world.getObjectParameter(SourceID, "recipeLevel", 0)
                if recipecheck(i) then
                    widget.setVisible(itemList .. ".add", false)
                    widget.setVisible(itemList .. ".remove", true)
                else
                    widget.setVisible(itemList .. ".add", true)
                    widget.setVisible(itemList .. ".remove", false)
                end
                if self.objectConfig.load then
                    widget.setButtonEnabled(itemList .. ".add", false)
                    widget.setButtonEnabled(itemList .. ".remove", false)
                end

                widget.setFontColor(itemList .. ".recipename", "red")
                widget.setVisible(itemList .. ".blockedbackground", true)
                widget.setButtonEnabled(itemList .. ".add", false)

                if config.level <= (self.level or recipeLevel) then
                    widget.setFontColor(itemList .. ".recipename", "green")
                    widget.setButtonEnabled(itemList .. ".add", true)
                    widget.setVisible(itemList .. ".blockedbackground", false)
                end

                widget.setImage(itemList .. ".border", "/interface/scripted/itemList/border/" .. config.level .. ".png" or "")
                if icon then
                    widget.setImage(itemList .. ".imageIcon", icon)
                    widget.setVisible(itemList .. ".icon", false)
                end
                widget.setText(itemList .. ".recipename", config.fullname or root.itemConfig(name).config.shortdescription or "-")
                widget.setItemSlotItem(itemList .. ".icon", config.icon or name)
                widget.setText(itemList .. ".level", "Lv." .. config.level or "-")
                widget.setData(itemList, {config = config, index = i})
                table.insert(self.buttons, itemList)
            end
        end
    end
end

function recipecheck(id)
    for c, _ in pairs(self.loadedrecipe) do
        if tonumber(c) == id then
            return true
        end
    end
    return false
end

function categorylist()
    self.forceReload = true
    self.curFilter = ui.dataReplacer(self.curFilter, ui.listDataExtract("categorylist"))
    widget.playSound(self.uiconfig.uiListSound)
end

function categoryCheck(groups)
    for _, currGroup in pairs(groups) do
        for _, group in pairs(self.curFilter) do
            if group == currGroup then
                return true
            end
        end
    end
    return false
end

function itemSelected()
    updateSelected()
    if self.data and self.data ~= self.dataSelected then
        self.dataSelected = self.data
    end
    swapRecipe()
end

function updateSelected()
    local itemList = widget.getListSelected(self.itemList)
    self.data = itemList and widget.getData(string.format("%s.%s", self.itemList, itemList)) or nil
end

function swapRecipe()
    inputList = "scroll.inputList"
    inputsList = "scroll.inputsList"
    outputList = "scroll.outputList"
    if self.dataSelected then
        local data = self.dataSelected.config

        widget.setVisible("scroll", true)

        widget.clearListItems(inputList)
        widget.clearListItems(outputList)

        widget.setItemSlotItem("titlelayout.icon", setIcon(data))
        local itemName = data.name or data.output[1].name
        widget.setText("titlelayout.title", data.fullName or root.itemConfig(itemName).config.shortdescription)
        widget.setText("titlelayout.level", "Level - " .. data.level or 1)

        for i, input in pairs(data.input) do
            local inputList = listfunction(inputList)

            if type(input.name) == "table" then
                widget.setItemSlotItem(inputList .. ".icon", input.name[1])
                widget.setVisible(inputList .. ".replacable", true)
                self.namesTooltips[inputList] = input.name
            else
                widget.setItemSlotItem(inputList .. ".icon", input.name)
            end

            widget.setText(inputList .. ".count", input.count)
        end
        local outputdata = outputbuild(data.output, self.recipes.pool)
        for i, output in pairs(outputdata) do
            widgetMove(outputList, inputList, "scroll.output", "scroll.label3")

            if output.name then
                local outputList = listfunction(outputList)
                widget.setItemSlotItem(outputList .. ".icon", output.name)

                if output.chance then
                    widget.setText(outputList .. ".chance", math.floor(output.chance * 100) .. "%")
                    widget.setVisible(outputList .. ".percent", true)
                else
                    widget.setText(outputList .. ".chance", "-")
                end
                if type(output.count) == "table" then
                    widget.setText(outputList .. ".count", output.count[1] .. "-" .. output.count[2])
                else
                    widget.setText(outputList .. ".count", output.count or 1)
                end
            end
        end

        local efficiency = world.getObjectParameter(SourceID, "efficiency", 0)
        local acceleration = world.getObjectParameter(SourceID, "acceleration", 0)
        local delay = data.delay or self.objectConfig.delay

        local consume = ""
        if self.fuel then
            consume = self.fuel.consume * (1 - efficiency)
        end
        if self.energy then
            consume = self.energy.euConsume * (1 - efficiency)
        end

        widget.setText("consume", string.format("%s", consume))
        widget.setText("timer", string.format("%.2f Sec", delay * (1 - acceleration)))
    end
end

function outputbuild(output, pool)
    local arr = {}
    for i, item in pairs(output) do
        if item.name then
            table.insert(arr, item)
        end

        if item.pool then
            for c, item in pairs(pool[item.pool]) do
                table.insert(arr, {name = item[2][1], count = item[2][2], chance = item[1]})
            end
        end
    end
    return arr
end

function treasuhepacker(pool, items)
    local treasure = root.assetJson(world.getObjectParameter(SourceID, "pool"))[pool]
    for i, config in pairs(treasure[1][2].pool) do
        if config.pool then
            treasuhepacker(config.pool, items)
        end
        table.insert(items, config)
    end
end

function getpos(name, option)
    if option == 0 then
        return widget.getPosition(name)
    else
        return widget.getPosition(name)[option]
    end
end

function setIcon(data)
    local parameters = {}
    local item = {}
    item.name = data.name or data.output[1].name
    item.count = 1
    if data.icon then
        parameters.inventoryIcon = data.icon
    end
    item.parameters = parameters
    return item
end

function setpos(name, h, v)
    if h == nil then
        h = getpos(name, 1)
    end
    return widget.setPosition(name, {h, v})
end

function getsize(name, option)
    if option == 0 then
        return widget.getSize(name)
    else
        return widget.getSize(name)[option]
    end
end

function log(log, text)
    sb.logInfo("%s %s", log, (text or "___"))
end

function listfunction(inputList)
    return string.format("%s.%s", inputList, widget.addListItem(inputList))
end

function widgetMove(list, upList, name, border)
    local listPos = getpos(upList, 2) - getsize(upList, 2)
    local borderSiz = getsize(border, 2)
    local textPlace = math.ceil(getsize(border, 2) / 2)

    setpos(list, nil, (listPos - (borderSiz + 2)))
    setpos(border, nil, (listPos - (borderSiz + 2)))
    setpos(name, nil, (listPos - (borderSiz - 3)))
end
