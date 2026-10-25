local SourceID

function init()
    SourceID = pane.sourceEntity() or pane.sourceEntity()
    self.itemList = "itemScroll.list"

    listItem()
end
function listItem()
    local list = world.getObjectParameter(SourceID, "itemList")
    local listIcon = config.getParameter("icons")[world.getObjectParameter(SourceID, "listItemsIcon") or "default"]

    widget.clearListItems(self.itemList)

    for _, item in pairs(list) do
        local listWidget = widget.addListItem(self.itemList)
        local itemList = string.format("%s.%s", self.itemList, listWidget)
        local text = item.energy or item.weight * 100

        sb.logInfo("%s", list)

        widget.setItemSlotItem(itemList .. ".icon", item.name)
        widget.setText(itemList .. ".count1", text)
        widget.setText(itemList .. ".count2", item.count)
        widget.setImage(itemList .. ".replacableImage", listIcon)
    end
end
