require "/scripts/util.lua"
require "/scripts/interp.lua"

require "/interface/scripts/ui_itemslot.lua"
descriptor = {}

function descriptor.init()
    layout = ("description")
    selectItem = nil
    descriptorReload = false
end

function descriptor.update()
    if descriptorReload and selectItem ~= nil then
        descriptor.descriptionWidget()
    end
    descriptorReload = false
end

function descriptor.slot(widgetName)
    selectItem = itemSlot.setItem(widgetName, item)
    descriptorReload = true
end

function descriptor.select(item)
    selectItem = item
    descriptorReload = true
end

function descriptor.clear()
    widget.removeAllChildren(layout)
end

function descriptor.descriptionWidget()
    --widget.removeAllChildren(layout)
    widget.removeAllChildren(layout)

    local item = root.itemConfig(selectItem)
    local tooltipKind = item.config.tooltipKind or "base"
    local itemDescriptor = root.assetJson("/interface/itemdescriptions/" .. tooltipKind .. ".itemdescription")
    local categories = root.assetJson("/items/categories.config:labels")
    local icon = item.config.largeImage or item.config.inventoryIcon
    if selectItem.parameters and next(selectItem.parameters) then
        tooltipFields = selectItem.parameters.tooltipFields
    else
        tooltipFields = item.config.tooltipFields
    end

    widget.addChild(layout, itemDescriptor.background, "background")

    for name, config in pairs(itemDescriptor) do
        if name ~= "background" then
            widget.addChild(layout, config, name)
        end
    end

    if tooltipFields then
        for k, v in pairs(tooltipFields) do
            if itemDescriptor[k] then
                if itemDescriptor[k].type == "label" then
                    widget.setText(layout .. "." .. k, v)
                end
                if itemDescriptor[k].type == "image" then
                    widget.setImage(layout .. "." .. k, v)
                end
            end
        end
    end

    widget.setImage(layout .. ".objectImage", util.absolutePath(item.directory, icon))

    widget.setItemSlotItem(layout .. ".titleIcon", selectItem)
    widget.setText(layout .. ".title", item.config.shortdescription)
    widget.setText(layout .. ".subTitle", categories[item.config.category] or "none")
    widget.setText(layout .. ".rarityLabel", string.lower(item.config.rarity))
    if itemDescriptor.descriptionLabel then
        widget.setText(layout .. ".descriptionLabel", item.config.description)
    end
end
