require "/scripts/util.lua"
require "/scripts/interp.lua"
itemSlot = {}

function itemSlot.setItem(widgetName)
    local playerItem = player.swapSlotItem()
    local data = widget.getData(widgetName) or 1
    local item = widget.itemSlotItem(widgetName)

    if not item then
        playerItem.count = playerItem.count - 1
        widget.setItemSlotItem(widgetName, {name = playerItem.name, count = 1, parameters = playerItem.parameters})
        player.setSwapSlotItem(playerItem)
    elseif item and not playerItem then
        player.setSwapSlotItem(item)
        widget.setItemSlotItem(widgetName, nil)
    elseif item and playerItem and not root.itemDescriptorsMatch(item, playerItem, true) then
        player.setSwapSlotItem(widget.itemSlotItem(widgetName))
        widget.setItemSlotItem(widgetName, playerItem)
    end
    return widget.itemSlotItem(widgetName)
end
