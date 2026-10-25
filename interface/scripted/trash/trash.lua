require "/interface/scripts/ui_storage_functions.lua"

function trash()
    local items = widget.itemGridItems("itemGrid")

    for i, item in pairs(items) do
        if root.itemType(item.name) == "generic" then
            ps.giveItem(item.name, item.count)
            world.containerConsumeAt(pane.containerEntityId(), i-1, item.count)
        end
        --root.itemType(item.name) == "generic"
    end
    sb.logInfo("%s", items)

    --world.containerTakeAll(pane.containerEntityId())
end
