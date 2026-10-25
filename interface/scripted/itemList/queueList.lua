queue = {}
function queue.init(SourceID)
    self.queueList = "queueScroll.list"
    self.itemSelectorData = {}

    self.recipeStack = {}
    for _, item in pairs(world.getObjectParameter(SourceID, "recipeList", {})) do
        table.insert(self.recipeStack, item)
    end
end

function queue.check(id)
    local reStack = {}
    for i, iConf in pairs(self.recipeStack) do
        if id == iConf.id then
            return false
        end
    end
    return true
end

function queue.listItem(forceReload, dt)
    if forceReload then
        widget.clearListItems(self.queueList)
        widget.setButtonEnabled("btnromoveItem", false)

        for i, config in pairs(self.recipeStack) do
            local name = config.name
            local id = config.id
            local icon = config.icon
            local fullname = config.fullname
            local listWidget = widget.addListItem(self.queueList)
            local queueList = string.format("%s.%s", self.queueList, listWidget)
            if config.recipe then
                widget.setText(queueList .. ".recipe", "^red;Blueprint is required!")
            else
                widget.setText(queueList .. ".recipe", "^green;Blueprint is not required!")
            end
            widget.setImage(
                queueList .. ".border",
                "/interface/scripted/itemList/border/" .. config.level .. ".png" or ""
            )
            if icon then
                widget.setImage(queueList .. ".imageIcon", icon)
                widget.setVisible(queueList .. ".icon", false)
            end
            widget.setText(queueList .. ".recipename", fullname or root.itemConfig(name).config.shortdescription or "-")
            widget.setItemSlotItem(queueList .. ".icon", name)
            if config.level <= self.level then
                widget.setButtonEnabled(queueList .. ".btnromoveItem", true)
                widget.setVisible(queueList .. ".lvlerror", false)
            else
                widget.setButtonEnabled(queueList .. ".btnromoveItem", true)
                widget.setVisible(queueList .. ".lvlerror", true)
            end
            widget.setText(queueList .. ".level", "Level " .. config.level or "-")
            widget.setData(
                queueList,
                {
                    index = i,
                    item = config
                }
            )
            if config == self.iSelected then
                widget.setListSelected(self.queueList, listWidget)
            end
        end
    end
end

function updateSelector()
    local queueList = widget.getListSelected(self.queueList)
    self.itemSelectorData = queueList and widget.getData(string.format("%s.%s", self.queueList, queueList)) or nil
end

function itemSelector()
    updateSelector()
    if self.itemSelectorData then
        self.iSelected = self.itemSelectorData
        self.dataSelected = self.itemSelectorData.item
    end
    swapRecipe()
    widget.setButtonEnabled("btnromoveItem", true)
end
