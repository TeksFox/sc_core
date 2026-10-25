require "/scripts/util.lua"
require "/scripts/interp.lua"
--require "/scripts/utils/ui_groupList.lua"
require "/scripts/utils/ui_utils.lua"

function init()
    player.setProperty("sf_configs", player.getProperty("sf_configs", root.assetJson("/configs/main.config:parameters")))
    selectData = {config = root.assetJson("/configs/main.config:layout")[1], losi = nil}

    widget.registerMemberCallback("settingsList", "options", options)
    widget.registerMemberCallback("settingsList", "optionVisible", optionVisible)

    listSettings(root.assetJson("/configs/main.config").layout, player.getProperty("sf_configs"))
    --switcherOptions(player.getProperty("sf_configs").parameters)
    addChildren(root.assetJson("/configs/main.config:layout")[1])
    setChecked()
    textUpdate()
end

function update(...)
    textUpdate()

    widget.setVisible("layout.falseImage", disablestatus())
end

function options(...)
end

function textUpdate()
    local config = player.getProperty("sf_configs")
    widget.setText("layout.sparkRadiusLabel", config.spark_radius or 0)
    widget.setText("layout.sparkCountLabel", config.spark_counts or 0)
    widget.setText("layout.sparkRateLabel", config.spark_rate or 0)
end

function options()
    addChildren(selectData.config)
end

function optionVisible(widgetName)
    if selectData then
        local parameters = player.getProperty("sf_configs")
        parameters[selectData.config.enabled] = widget.getChecked(selectData.list .. "." .. widgetName)

        player.setProperty("sf_configs", parameters)
        world.sendEntityMessage(player.id(), "updateConfig")
    end
end

function addChildren(main)
    widget.removeAllChildren("layout")
    local widgets = root.assetJson(main.layoutpath)
    local config = player.getProperty("sf_configs")

    widget.addChild("layout", widgets.background, "background")

    for name, config in pairs(widgets) do
        if name ~= "background" and name ~= "falseImage" then
            widget.addChild("layout", config, name)
        end
    end
    widget.addChild("layout", widgets.falseImage, "falseImage")
end

function setChecked()
    local config = player.getProperty("sf_configs")
    widget.setChecked("layout.hideTileSwitch", config.spark_tiles)
    widget.setChecked("layout.hideObjectSwitch", config.spark_objects)
    widget.setChecked("layout.hideObjectArrow", config.spark_arrow)
end

function disablestatus()
    return selectData ~= nil and not player.getProperty("sf_configs")[selectData.config.enabled]
end

function optionUP(widgetName)
    local wName = "layout." .. widgetName
    local data = widget.getData(wName).localAnimator
    local parameters = player.getProperty("sf_configs")
    if parameters[data.option] < data.countMax then
        parameters[data.option] = parameters[data.option] + data.count
    end

    player.setProperty("sf_configs", parameters)
    world.sendEntityMessage(player.id(), "updateConfig")
end

function optionDOWN(widgetName)
    local wName = "layout." .. widgetName
    local data = widget.getData(wName).localAnimator
    local parameters = player.getProperty("sf_configs")
    if parameters[data.option] > data.countMin then
        parameters[data.option] = parameters[data.option] - data.count
    end

    player.setProperty("sf_configs", parameters)
    world.sendEntityMessage(player.id(), "updateConfig")
end

function optionPlayerProperty(widgetName, widgetData)
    player.setProperty(widgetData.localAnimator.targetParameter, widgetData.localAnimator.parametersSet)
end

function optionSwitch(widgetName)
    local wName = "layout." .. widgetName
    local data = widget.getData(wName).localAnimator
    local parameters = player.getProperty("sf_configs")
    parameters[data.option] = widget.getChecked(wName)

    if data.optionDisable then
        widget.setChecked("layout." .. data.optionDisable, false)
    end

    player.setProperty("sf_configs", parameters)
    world.sendEntityMessage(player.id(), "updateConfig")
end

function restoreButton()
    player.setProperty("localanimator", localConfig.defaultConfig)
end

function listSettings(main)
    widget.clearListItems("settingsList")

    table.sort(
        main,
        function(a, b)
            return a.id < b.id
        end
    )
    for i, config in pairs(main) do
        local listWidget = widget.addListItem("settingsList")
        local list = string.format("%s.%s", "settingsList", listWidget)

        --
        widget.setChecked(list .. ".optionVisible", player.getProperty("sf_configs")[config.enabled])
        widget.setText(list .. ".options", config.text)
        widget.setData(list, {parameters = config, list = list})

        widget.setData(list, {config = config, list = list})
    end
end

function settingsList()
    selectData = ui_utils.dataReplacer(selectData, ui_utils.listDataExtract("settingsList"), root.assetJson("/configs/main.config").layout[1])
end

function resComp(slots, res)
    for i, item in pairs(slots) do
        if item == res then
            return false
        end
    end
    return true
end

function recolor(res)
    local color = localcolors[res]
    local paletteSwaps = ""
    for k, v in pairs(color) do
        paletteSwaps = string.format("%s?replace=%s=%s", paletteSwaps, k, v)
    end
    return paletteSwaps
end

function restore(...)
    player.setProperty("localanimator", root.assetJson("/configs/localanimator.config").defaultConfig)
    init()
end
