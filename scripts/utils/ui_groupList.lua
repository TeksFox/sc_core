require "/interface/scripts/uiComponents.lua"
category = {}

function category.init(uiconfig)
    local uilist = nil
    if type(uiconfig) == "table" then
        uilist = uiconfig.category
    else
        uilist = root.assetJson("/configs/guiconfig.config").uiparameters[uiconfig].category
    end

    local categorySort = {}
    for _, config in pairs(uilist) do
        table.insert(categorySort, config)
    end
    widget.clearListItems("categorylist")
    for i, config in ipairs(categorySort) do
        local cListWidget = widget.addListItem("categorylist")
        local cList = string.format("%s.%s", "categorylist", cListWidget)
        if config.selected then
            widget.setListSelected("categorylist", cListWidget)
            self.curFilter = config.category
        end
        widget.setImage(cList .. ".icon", config.icon or "/interface/scripted/itemList/icons/error.png")
        widget.setData(cList, config.category)

        self.toolTipList[string.format("%s.%s", "categorylist", cListWidget)] = config
    end
end

function categorylist()
    self.forceReload = true
    self.curFilter = ui.dataReplacer(self.curFilter, ui.listDataExtract("categorylist"))
    if self.sound then
        widget.playSound(config.getParameter("buttonClickSound", "/sfx/interface/clickon_success.ogg"))
    end
end
