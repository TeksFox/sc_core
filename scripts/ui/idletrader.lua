require "/scripts/util.lua"
require "/scripts/interp.lua"
sampleSpinner = {}

function init()
    sourceID = pane.containerEntityId()
    guiConf = world.getObjectParameter(sourceID, "guiConf")

    self.reloadList = true
    self.itemList = "buylayout.itemScroll.list"
    self.sellList = "selllayout.itemScroll.list"
    self.amount = 1

    self.tradelist = root.assetJson(guiConf.tradeList)

    self.curFilter = ""
    self.selectedItem = ""
    self.dataSelected = nil

    loadWidget()
    widget.setButtonEnabled("buylayout.buyButton", false)
    widget.setItemSlotItem("buylayout.moneyicon", guiConf.currencytype)
    widget.setItemSlotItem("selllayout.moneyicon", guiConf.currencytype)
    if guiConf.shopselling ~= true then
        widget.setButtonEnabled("buttonSellGroup", false)
    end

    sellList()
end

function loadWidget()
    widget.setVisible("itemGrid", false)
    widget.setVisible("input", false)

    widget.setVisible("selllayout", false)
    widget.setVisible("buylayout", true)
    widget.setButtonImage("buttonSellGroup", "/interface/scripted/idletrader/copy.png:1")
    widget.setButtonImage("buttonBuyGroup", "/interface/scripted/idletrader/copy.png:3")
end

function buyGroup()
    loadWidget()
end

function sellGroup()
    widget.setVisible("itemGrid", true)
    widget.setVisible("input", true)

    widget.setVisible("selllayout", true)
    widget.setVisible("buylayout", false)
    widget.setButtonImage("buttonBuyGroup", "/interface/scripted/idletrader/copy.png:1")
    widget.setButtonImage("buttonSellGroup", "/interface/scripted/idletrader/copy.png:3")
end

function update()
    widget.setText("buylayout.playerMoney", player.currency(guiConf.currencytype))
    widget.setText("selllayout.playerMoney", player.currency(guiConf.currencytype))
    if self.dataSelected then
        local iPrice = self.dataSelected.price
        local playerCurr = player.currency(guiConf.currencytype)
        local maxNum = math.floor(playerCurr / iPrice)

        if player.currency(guiConf.currencytype) < iPrice then
            widget.setButtonEnabled("buylayout.buttonBuy", false)
            widget.setVisible("buylayout.sampleSpinner", false)
            widget.setText("buylayout.totalBuyPrice", 0)
            widget.setText("buylayout.count", 0)
        else
            widget.setButtonEnabled("buylayout.buttonBuy", true)
            widget.setVisible("buylayout.sampleSpinner", true)
        end
        if self.amount <= 0 then
            self.amount = maxNum
            if maxNum > 1000 then
                self.amount = 1000
            end
        end
        if self.amount > maxNum then
            self.amount = 1
        end
        if self.amount > 1000 then
            self.amount = 1
        end
        widget.setText("buylayout.totalBuyPrice", iPrice * self.amount)
        widget.setText("buylayout.count", self.amount)
    else
        if self.amount <= 0 then
            self.amount = 1
        end
        widget.setText("buylayout.totalBuyPrice", 0)
        widget.setText("buylayout.count", 0)
        widget.setVisible("buylayout.sampleSpinner", false)
        widget.setButtonEnabled("buylayout.buttonBuy", false)
    end

    widget.setText("selllayout.totalsellPrice", totalPrice())
    tradeList(self.reloadList)

    self.reloadList = false
end

function tradeList(reloadList)
    if reloadList then
        local tradeSort = {}
        widget.clearListItems(self.itemList)

        for _, config in pairs(self.tradelist.buyItems) do
            table.insert(tradeSort, config)
        end
        table.sort(
            tradeSort,
            function(a, b)
                return a.price > b.price
            end
        )
        for _, config in pairs(tradeSort) do
            local listWidget = widget.addListItem(self.itemList)
            local itemList = string.format("%s.%s", self.itemList, listWidget)
            local iConf = root.itemConfig(config.item).config

            widget.setItemSlotItem(itemList .. ".icon", config.item)
            widget.setText(itemList .. ".recipename", iConf.shortdescription)
            widget.setText(itemList .. ".price", config.price)

            if player.currency(guiConf.currencytype) < config.price then
                widget.setVisible(itemList .. ".notcraftableoverlay", true)
            else
                widget.setVisible(itemList .. ".notcraftableoverlay", false)
            end

            widget.setData(itemList, config)

            if config == self.itemSelected then
                widget.setListSelected(self.itemList, listWidget)
            end
        end
    end
end
function sellList()
    widget.clearListItems(self.sellList)

    sb.logInfo("%s", self.tradelist.sellItems)
    local sellList = {}
    for k, v in pairs(self.tradelist.sellItems) do
        table.insert(sellList, {k, v})
    end
    table.sort(
        sellList,
        function(a, b)
            return a[2] > b[2]
        end
    )
    sb.logInfo("%s", sellList)
    for _, item in pairs(sellList) do
        local listWidget = widget.addListItem(self.sellList)
        local sellList = string.format("%s.%s", self.sellList, listWidget)
        local iConf = root.itemConfig(item[1]).config

        -- sb.logInfo("%s", iConf)

        widget.setItemSlotItem(sellList .. ".icon", item[1])
        widget.setText(sellList .. ".recipename", iConf.shortdescription)
        widget.setText(sellList .. ".price", item[2])
    end
end

function itemSelected()
    updateSelected()
    if self.dataSelected then
        self.itemSelected = self.dataSelected
    end

    self.amount = 1
end

function updateSelected()
    local itemList = widget.getListSelected(self.itemList)
    self.dataSelected = itemList and widget.getData(string.format("%s.%s", self.itemList, itemList)) or nil
end

function buttonBuy()
    if self.dataSelected then
        player.consumeCurrency(guiConf.currencytype, self.dataSelected.price * self.amount)
        player.giveItem({name = self.dataSelected.item, count = 1 * self.amount})
        --guiConf
        self.amount = 1
        self.reloadList = true
    end
end

function sampleSpinner.up()
    self.amount = self.amount + 1
end

function sampleSpinner.down()
    self.amount = self.amount - 1
end

function buttonSell()
    world.containerTakeAll(sourceID)
    local total = totalPrice()
    if total > 0 then
        player.giveItem({name = guiConf.currencytype, count = total})
    end
    self.reloadList = true
end

function totalPrice()
    local value = 0
    local cItems = widget.itemGridItems("itemGrid")
    for _, item in pairs(cItems) do
        if self.tradelist.sellItems[item.name] then
            value = value + (self.tradelist.sellItems[item.name] or 0) * item.count
        end
    end
    return value
end
