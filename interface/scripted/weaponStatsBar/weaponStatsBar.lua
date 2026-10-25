require "/scripts/interp.lua"
require "/interface/scripts/ui_Components.lua"

function init()
    resourceList = root.assetJson("/configs/statusbar.config")
    barImageAsset = config.getParameter("dataImage")

end

function update()
    --status.modifyResource("radiation", 0.5)
    widget.clearListItems("statusResourceList")

    for _, config in pairs(resourceList.statusBarResources) do
        local filter = true
        if filter == true then
            filter = config.type == "persistent"
        end
        if config.type == "declining" then
            filter = status.resource(config.resource) < status.resourceMax(config.resource)
        end

        if config.type == "increase" then
            filter = status.resource(config.resource) > 0
        end

        if filter then
            local listWidget = widget.addListItem("statusResourceList")
            local list = string.format("%s.%s", "statusResourceList", listWidget)
            local stat = status.resourcePercentage(config.resource)
            widget.setImage(list .. ".icon", config.icon)
            widget.setImage(list .. ".progressImage", ui.progressImage(barImageAsset, stat, config.resource, "/configs/palettes/statusresourcecolor.config"))
        end
    end
end

function uninit( ... )
    player.setProperty("startHud", false)
    -- body
end
