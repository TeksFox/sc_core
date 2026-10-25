require "/interface/scripts/ui_tooltip.lua"
require "/interface/scripted/crafting_recipeLoader.lua"

function init()
    self.SourceID = pane.sourceEntity()
    self.toolTipList = {}
    self.itemList = "scroll.list"
    self.curFilter = {}
    self.curSearch = ""
    self.forceReload = true
    self.coreconnected = world.getObjectParameter(self.SourceID, "coreconnected")

    if not self.coreconnected then
        widget.setVisible("errorLabel", true)
    end

    listItem(forceReload)
end

function update()
    listItem(self.forceReload)
    self.forceReload = false
end

function categorylist()
    self.curFilter = ui.dataReplacer(self.curFilter, ui.listDataExtract("categorylist"))
    self.forceReload = true
end

function getText()
    return widget.getText("filter"):lower()
end

function filter()
    local search = getText()
    if self.curSearch ~= search then
        self.curSearch = search:lower()
        self.forceReload = true
    end
end

function listItem(forceReload)
    if self.forceReload then
        widget.clearListItems(self.itemList)
        local listedItems = player.getProperty("personalstorage", {})

        sb.logInfo("%s", listedItems)
        local arr = {}
        for name, item in pairs(listedItems) do
            table.insert(arr, item)
        end
        table.sort(
            arr,
            function(a, b)
                return a.count > b.count
            end
        )

        --sb.logInfo("%s", listedItems)
        if arr and next(arr) then
            for _, item in pairs(arr) do
                local config = root.itemConfig(item).config
                local filter = true
                if filter and (self.curSearch ~= "") then
                    filter = (string.find(config.shortdescription:lower(), self.curSearch) ~= nil)
                end
                if filter then
                    local listWidget = widget.addListItem(self.itemList)
                    local itemList = string.format("%s.%s", self.itemList, listWidget)


            sb.logInfo("%s", widget.getPosition(itemList))
                    widget.setImage(itemList .. ".rarity", "/interface/scripted/personalstorage/backRarity.png:" .. config.rarity:lower())
                    if item.count < 9999 then
                        widget.setText(itemList .. ".count", item.count)
                    else
                        widget.setText(itemList .. ".count", "9999")
                    end
                    if item.count == 0 then
                        widget.setText(itemList .. ".count", "---")
                    end
                    widget.setItemSlotItem(itemList .. ".icon", item.name)
                    widget.setData(itemList, rec)
                end
            end
        end
    end
end

function createTooltip(screenPosition)
    for wName, data in pairs(self.toolTipList) do
        if widget.inMember(wName, screenPosition) then
            return tooltips.creation(screenPosition, data)
        end
    end
end
