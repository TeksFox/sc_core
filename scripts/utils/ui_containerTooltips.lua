require "/scripts/util.lua"
require "/scripts/interp.lua"
tooltips = {}

function tooltips.creation(data)
    local text = data.text or data

    --Для правильного отображения подсказки
    --Нужно создть невидимый текстовый виджет "spectralText", имеющий параметры положения текста а также ширину текста и размер шрифта
    --при его отсутствие текст будет не корректно отображаться
    widget.setText("spectralText", text)
    local tooltip = root.assetJson("/interface/craftingtooltip/widgettooltip.pane")
    local size = widget.getSize("spectralText")
    tooltip.background.fileBody = "/interface/smarttubes/extractionconduit/tooltip_body.png?scalenearest=1;" .. size[2] + 10
    tooltip.text.value = copy(text)
    tooltip.text.position[2] = tooltip.text.position[2] + size[2] + 5

    return tooltip
end
