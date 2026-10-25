category = {}

function category.init(uiconfig)

    local categorySort = {}
    for _, config in pairs(root.assetJson("/configs/guiconfig.config").uiparameters[uiconfig]) do
        table.insert(categorySort, config)
    end
    table.sort(
        categorySort,
        function(a, b)
            return a.order < b.order
        end
    )
    widget.clearListItems("categorylist")
    for i, config in pairs(categorySort) do
        local cListWidget = widget.addListItem("categorylist")
        local cList = string.format("%s.%s", "categorylist", cListWidget)
        
        if config.selected then
            widget.setListSelected("categorylist", cListWidget)
            self.curFilter = config.category
        end

        widget.setImage(cList .. ".icon", config.icon or "/interface/scripted/itemList/icons/error.png")
        widget.setData(cList, config)

        if config == self.selectCategory then
            widget.setListSelected("categorylist", cListWidget)
        end
        
        self.toolTipList[string.format("%s.%s", "categorylist", cListWidget)] = config
    end
end

function category.update()
    local cList = widget.getListSelected("categorylist")
    self.categoryData = cList and widget.getData(string.format("%s.%s", "categorylist", cList)) or nil
end

function category.select()
    self.forceReload = true
    if self.categoryData then
        self.selectCategory = self.categoryData
    end
end

function category.Data()
    if self.categoryData then
        if self.curFilter ~= self.categoryData.category then
            self.curFilter = self.categoryData.category
            self.forceReload = true
        end
    end
end

function categorylist()
    category.update()
    category.select()
    category.Data()
end
