require "/scripts/util.lua"
require "/scripts/interp.lua"

require "/interface/scripts/ui_tooltip.lua"
require "/interface/scripts/ui_Components.lua"
require "/interface/scripted/crafting_recipeLoader.lua"
local SourceID

local OldInit = init
local OldUpdate = update
local filter = true

function recipeInit(list, id)
    SourceID = pane.sourceEntity()

    local objectfilters = world.getObjectParameter(SourceID, "objectfilters", nil)
    local arr = {}

    for _, item in pairs(list) do
        if recipeFind(item.groups, objectfilters) then
            table.insert(arr, item)
        end
    end

    table.sort(
        arr,
        function(a, b)
            return a.output.name < b.output.name
        end
    )
    return arr
end

function recipeFind(groups, objectfilters)
    for _, name in pairs(groups) do
        for _, f in pairs(objectfilters) do
            if name == f then
                return true
            end
        end
    end
    return false
end

function init()
    SourceID = player.getProperty("objectID", nil) or pane.sourceEntity()
    self.recipes = recipeInit(root.allRecipes(), SourceID)

    self.crafts = world.getObjectParameter(SourceID, "crafts", {})
    --self.recipes = root.assetJson(world.getObjectParameter(SourceID, "recipes", {}))

    self.line = world.getObjectParameter(SourceID, "line", {})
    self.upgrade = world.getObjectParameter(SourceID, "upgrade", nil)

    self.itemList = "itemScroll.list"
    self.filterHaveMaterials = widget.getChecked("btnFilterHaveMaterials")
    self.uiconfig = nil
    self.toolTipList = {}
    self.toolTipsCraftList = {}
    self.toolCraftButtons = {}

    self.shift = false

    self.descriptor = false
    self.oldIndex = ""
    self.curFilter = {}
    self.curSearch = ""
    self.selectedItem = ""
    self.selectCategory = ""
    self.multipler = 1
    self.buttonSelected = nil

    self.forceShift = true
    self.oldShift = false

    self.forceReload = true
    self.completeReload = true
    self.listreload = true
    self.completelistreload = true

    if not self.upgrade then
        widget.setVisible("upgrade", false)
    end

    self.tooltipsConfig = {}

    ui.init(world.getObjectParameter(SourceID, "objectName"))
    self.sound = true
    world.sendEntityMessage(SourceID, "statReload")

    widget.setButtonEnabled("btnPersonalStorageEnabler", true)
    widget.setButtonEnabled("itemScroll.craftButtons.give", false)

    widget.setButtonEnabled("manualcraft", false)
    widget.setItemSlotItem("titleIcon", world.getObjectParameter(SourceID, "objectName"))
    pane.setTitle(root.itemConfig(world.getObjectParameter(SourceID, "objectName")).config.shortdescription, "Automatic craft station")
    if OldInit ~= nil then
        OldInit()
    end
    listItem(self.forceReload)
    ps.check()
end

function upgrade()
    if ui.canCraft(self.upgrade.upgradeMaterials) or player.isAdmin() then
        if not player.isAdmin() then
            ui.craftConsume(self.upgrade.upgradeMaterials)
        end
        world.sendEntityMessage(SourceID, "upgrade")
        pane.dismiss()
    end
end

function update(dt)
    self.shift = input.key("LShift")
    if self.shift ~= self.oldShift then
        self.oldShift = self.shift
        self.forceShift = true
    end

    if self.descriptor and input.key("R") then
        if widget.getChecked("descriptor.craftSearch") then
            widget.setChecked("descriptor.craftSearch", false)
        else
            widget.setChecked("descriptor.craftSearch", true)
        end
        craftSearch()
    end

    search()
    listItem(self.forceReload)

    if OldUpdate ~= nil then
        OldUpdate()
    end
    listUpdate(world.getObjectParameter(SourceID, "crafts", {}), self.shift)
    inputListUpdate(self.shift)

    self.forceReload = false
end

function inputListUpdate(shift)
    if self.descriptor then
        widget.clearListItems("descriptor.inputList")
        for i, item in pairs(self.descriptorData.input) do
            local playerItems = ui.getAmount(item, shift)
            local itemCount = item.count
            if input.key("LShift") then
                itemCount = itemCount * 5
            end
            local listWidget = widget.addListItem("descriptor.inputList")
            local itemList = string.format("%s.%s", "descriptor.inputList", listWidget)

            if ui.hasEnough(item, shift) and playerItems > itemCount then
                playerItems = itemCount
            end

            widget.setItemSlotItem(itemList .. ".icon", item.name)
            widget.setText(itemList .. ".name", root.itemConfig(item.name).config.shortdescription)
            widget.setText(itemList .. ".count", string.format("%s^white;|^reset;%s", playerItems, itemCount))
            widget.setFontColor(itemList .. ".count", string.format("%s", ui.setColor(item, shift)))
        end
    end
end

function listUpdate(list, shift)
    widget.setText("descriptor.craftLine", 0)
    widget.setText("descriptor.completeCount", 0)
    --widget.setProgress("descriptor.progressBar", 0)

    if self.descriptor and list[self.descriptorData.name] and list[self.descriptorData.name].counts[2] > 0 then
        widget.setButtonEnabled("descriptor.give", true)
    else
        widget.setButtonEnabled("descriptor.give", false)
    end
    for _, rec in pairs(self.recipes) do
        local item = rec.output.name
        local currCount = 0
        local compCount = 0
        local progress = 0

        if list[item] then
            currCount = list[item].counts[1]
            compCount = list[item].counts[2]
            progress = 1 - ((list[item].start - world.time()) / list[item].duration)

            if self.descriptor then
                if list[self.descriptorData.name] then
                    widget.setText("descriptor.craftLine", list[self.descriptorData.output.name].duration)
                    widget.setText("descriptor.craftLine", list[self.descriptorData.output.name].counts[1] or 0)
                    widget.setText("descriptor.completeCount", list[self.descriptorData.output.name].counts[2] or 0)

                    local prog = 1 - ((list[self.descriptorData.output.name].start - world.time()) / list[self.descriptorData.output.name].duration)

                    if prog * 100 < 100 then
                        widget.setText("descriptor.progress", string.format("%.2f %%", prog * 100))
                        widget.setProgress("descriptor.progressBar", prog)
                    else
                        widget.setText("descriptor.progress", "0")
                        widget.setProgress("descriptor.progressBar", 0)
                    end
                end
            end
        end

        if self.descriptor then
            if ui.canCraft(self.descriptorData.input, shift) then
                widget.setButtonEnabled("buttonadd", true)
            else
                widget.setButtonEnabled("buttonadd", false)
            end
        end

        if rec.duration then
            if progress < 1 then
                widget.setProgress("itemScroll.layout" .. item .. ".progressBar", progress)
            else
                widget.setProgress("itemScroll.layout" .. item .. ".progressBar", 0)
            end
            if ui.canCraft(rec.input) or player.isAdmin() then
                widget.setButtonEnabled("itemScroll.layout" .. item .. ".addone", true)
            else
                widget.setButtonEnabled("itemScroll.layout" .. item .. ".addone", false)
            end

            if progress < 1 and progress ~= 0 then
                widget.setButtonEnabled("itemScroll.layout" .. item .. ".remove", true)
            else
                widget.setButtonEnabled("itemScroll.layout" .. item .. ".remove", false)
            end

            -- local str = "|  ^yellow;%s^white;  |  ^orange;%s^white;  |  ^cyan;%s^white;  |"
            local str = "^yellow;%s^white; | ^green;%s^white;"

            widget.setText("itemScroll.layout" .. item .. ".lblcraftcounts", string.format(str, currCount, compCount))
        end
    end

    -- body
end

function btnFilterHaveMaterials(widgetName)
    self.forceReload = true
    self.filterHaveMaterials = widget.getChecked("btnFilterHaveMaterials")
end

function listupdateselection()
    local itemList = widget.getListSelected("recipeButtonList")
    self.buttonSelected = itemList and widget.getData(string.format("%s.%s", "recipeButtonList", itemList)) or nil
end

function add(wName)
    self.shift = input.key("LShift")
    self.forceShift = true
    local wData = self.descriptorData
    local name = wData.output.name
    wData.count = 1
    if self.shift then
        wData.count = 5
    end
    local list = world.getObjectParameter(SourceID, "crafts", {})
    if wData.duration then
        if list[wData.name] then
            if ui.canCraft(wData.input) or player.isAdmin() then
                ui.consumeItems(wData.input, self.shift)
                world.sendEntityMessage(SourceID, "add", wData)
            end
        elseif ui.canCraft(wData.input) or player.isAdmin() then
            ui.consumeItems(wData.input, self.shift)
            world.sendEntityMessage(SourceID, "add", wData)
        end
    else
        ui.addItems({name = wData.name, count = wData.output.count})
    end
end

function remove(wName)
    local wData = self.descriptorData
    local name = wData.output.name
    local list = world.getObjectParameter(SourceID, "crafts", {})

    if list[wData.name] and list[wData.name].counts[1] > 0 then
        for _, item in pairs(list[wData.name].input) do
            for i = 1, 100 do
                local count = 1000
                local itemCount = item.count * list[wData.name].counts[1]
                repeat
                    if itemCount < count then
                        count = itemCount
                    end
                    ui.addItems({name = item.name, count = count})

                    itemCount = itemCount - count
                until itemCount == 0

                world.sendEntityMessage(SourceID, "recipeRemove", wData.name)

                widget.setText("descriptor.craftLine", 0)
                break
            end
        end
    end
end

function give(wName, wData)
    local wData = self.descriptorData
    local list = world.getObjectParameter(SourceID, "crafts", {})
    for i = 1, 100 do
        local count = 1000
        local itemCount = wData.output.count * list[wData.name].counts[2]
        repeat
            if itemCount < count then
                count = itemCount
            end
            ui.addItems({name = wData.name, count = count})

            itemCount = itemCount - count
        until itemCount == 0

        world.sendEntityMessage(SourceID, "giveall", wData.name)

        widget.setText("descriptor.completeCount", 0)
        break
    end
end

function craftDesc(widgetName, widgtData)
    widget.setVisible("descriptor", true)
    craftDescInput(widgtData)
end

function craftDescInput(data)
    local itemInSearch = player.getProperty("searchRecipes", {})

    widget.setText("descriptor.progress", "0")
    widget.setProgress("descriptor.progressBar", 0)

    self.descriptor = true
    self.descriptorData = data

    if self.oldIndex ~= data.name then
        self.oldIndex = data.name
    end

    local outputList = "descriptor.outputList"

    widget.clearListItems(outputList)

    widget.setItemSlotItem("descriptor.itemIcon", data.name)
    widget.setText("descriptor.nameLabel", root.itemConfig(data.name).config.shortdescription)

    widget.setPosition("itemScroll.craftButtons", {20, data.position + 2})
    widget.setVisible("itemScroll.craftButtons", true)

    local duration = string.format("%sh %sm %.2fs", math.floor(data.duration / 3600), math.floor(data.duration / 60 % 60), data.duration % 60)

    widget.setText("descriptor.duration", duration)
    widget.setText("descriptor.maximumCount", data.maxCount or 10)
    inputListUpdate(shift)

    widget.setText("descriptor.outputTextLabel", root.itemConfig(data.name).config.shortdescription .. " x" .. data.output.count)

    widget.setItemSlotItem("descriptor.outputIcon", data.name)
    --local startPos = widget.getPosition(inputList)[2]

    -- widget.setPosition("descriptor.outputList", {0, startPos - 30 - (22 * (#data.input - 1))})
    -- widget.setPosition("descriptor.outputLabel", {66, startPos - 25 - (22 * (#data.input - 1))})
end

function getText()
    return widget.getText("filter")
end

function craftSearch()
    if self.descriptor then
        local searchCraft = player.getProperty("searchRecipes", {})

        if not searchCraft[self.descriptorData.name] then
            searchCraft[self.descriptorData.name] = self.descriptorData
        else
            searchCraft[self.descriptorData.name] = nil
        end
        player.setProperty("searchRecipes", searchCraft)
    end
    self.forceReload = true
    --self.descriptor = nil
end

function search()
    local search = getText()
    if self.curSearch ~= search then
        self.curSearch = search
        self.forceReload = true
    end
end

function listItem(forceReload)
    if forceReload then
        local itemInSearch = player.getProperty("searchRecipes", {})
        widget.removeChild("itemScroll", "craftButtons")
        --widget.removeAllChildren("itemScroll")
        local iConut = 0

        for _, i in pairs(self.recipes) do
            widget.removeChild("itemScroll", "layout" .. i.output.name)
        end
        local scrollSize = widget.getSize("itemScroll")
        widget.clearListItems(self.itemList)
        widget.setButtonEnabled("btnAddRecipe", false)
        local columns = 0
        local list = 0
        for i, rec in pairs(self.recipes) do
            local item = rec.output.name
            local iConf = root.itemConfig(item)
            local filter = true

            if filter then
                filter = recipe.check(rec.groups, self.curFilter) == true
            end

            if filter and self.filterHaveMaterials == true then
                filter = ui.canCraft(rec.input)
            end

            if filter and (self.curSearch ~= "") then
                filter = (string.find(iConf.config.shortdescription:lower(), self.curSearch:lower()) ~= nil)
            end

            if filter then
                local widgets = config.getParameter("list")

                widgets.layout.position = {(widgets.layout.size[1]), ((widgets.layout.size[2] + 2) * -list)}

                widget.addChild("itemScroll", widgets.layout, "layout" .. item)

                widget.setItemSlotItem("itemScroll.layout" .. item .. ".icon", item)
                widget.setImage("itemScroll.layout" .. item .. ".recipeRarityImage", "/interface/scripted/crafting/backRarity.png:"..iConf.config.rarity:lower())

                if itemInSearch[item] then
                    widget.setVisible("itemScroll.layout" .. item .. ".searched", true)
                else
                    widget.setVisible("itemScroll.layout" .. item .. ".searched", false)
                end

                widget.setText("itemScroll.layout" .. item .. ".name", iConf.config.shortdescription .. " x" .. rec.output.count)
                widget.setData(
                    "itemScroll.layout" .. item .. ".craftDescription",
                    {
                        name = rec.output.name,
                        input = rec.input,
                        duration = rec.duration,
                        output = rec.output,
                        position = ((widgets.layout.size[2] + 2) * -list)
                    }
                )
                widget.setData("itemScroll.layout" .. item .. ".giveallitems", rec.output)

                self.toolTipsCraftList["itemScroll.layout" .. item .. ".craftDescription"] = rec

                if ui.canCraft(rec.input) then
                    widget.setVisible("itemScroll.layout" .. i .. ".lblnocancraft", false)
                end
                for _, cItem in pairs(rec.input) do
                    local listWidget = widget.addListItem("itemScroll.layout" .. item .. ".itemlist")
                    local itemList = string.format("%s.%s", "itemScroll.layout" .. item .. ".itemlist", listWidget)

                    local pCount = player.hasCountOfItem(cItem.name)
                    if pCount >= 1000 then
                        pCount = 999
                    end
                    widget.setItemSlotItem(itemList .. ".icon", cItem.name)
                    widget.setText(itemList .. ".count", string.format("%s/%s", pCount, cItem.count))
                    widget.setFontColor(itemList .. ".count", ui.hasEnough(cItem) and "green" or "red")
                end
                columns = columns + 1
                if columns > 0 then
                    columns = 0
                    list = list + 1
                end
            end
        end
        widget.addChild("itemScroll", config.getParameter("craftButtons"), "craftButtons")
    end
end

function categorylist()
    self.forceReload = true
    self.curFilter = ui.dataReplacer(self.curFilter, ui.listDataExtract("categorylist"))

    widget.setPosition("itemScroll.craftButtons", {-9999, -9999})
    widget.setVisible("descriptor", false)
    self.descriptor = false
    self.descriptorData = nil
end
--

function createTooltip(screenPosition)
    for wName, data in pairs(self.toolTipList) do
        if widget.inMember(wName, screenPosition) then
            return tooltips.creation(screenPosition, data)
        end
    end

    for wName, data in pairs(self.toolCraftButtons) do
        if widget.inMember(wName, screenPosition) then
            return tooltips.creation(screenPosition, data)
        end
    end

    for wName, data in pairs(self.toolTipsCraftList, self.shift) do
        if widget.inMember(wName, screenPosition) then
            -- local parameters = {duration = string.format("%.2f", data.duration)}
            return tooltips.listCreation(data, false, "compare", "INGREDIENTS", false, false, false, self.shift)
        end
    end
    if widget.inMember("upgrade", screenPosition) then
        local iConf = root.itemConfig(self.upgrade.upgradeobject)
        local image = iConf.config.largeImage or iConf.config.placementImage or ""
        local largeImage = {
            image = util.absolutePath(iConf.directory, image),
            oldobjectName = root.itemConfig(self.upgrade.upgradeobject).config.shortdescription
        }
        return tooltips.listCreation(self.upgrade.upgradeMaterials, {"largeImage"}, "compare", "UPGRADE INGREDIENTS", {largeImage = largeImage})
    end

    return tooltips.creation(screenPosition)
end

function uninit(...)
    player.setProperty("objectID", nil)
    player.setProperty("specialUI", false)
end
