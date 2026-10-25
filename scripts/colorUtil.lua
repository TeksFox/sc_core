require "/scripts/util.lua"
require "/scripts/interp.lua"

local oldinit = init
function init()
    if oldinit ~= nil then
        oldinit()
    end
    --! Стандартные параметры, запрос на палитру
    colorOptions = config.getParameter("colorOptions")
    paleteList = root.assetJson("/configs/palettes/factoryColor.config")

    basePart = colorOptions.colorableParts.basePart
    altPart = colorOptions.colorableParts.altPart

    storage.baseprimary = storage.baseprimary or primaryColor().baseprimary[1]
    storage.basesecondary = storage.basesecondary or primaryColor().basesecondary[1]
    baseColor = tostring(storage.baseprimary) .. tostring(storage.basesecondary)

    if altPart then
        storage.altprimary = storage.altprimary or primaryColor().altprimary[1]
        storage.altsecondary = storage.altsecondary or primaryColor().altsecondary[1]
        altColor = tostring(storage.altprimary) .. tostring(storage.altsecondary)
    end

    animator.setPartTag(basePart, "basecolor", baseColor)
    if altPart then
        animator.setPartTag(altPart, "altcolor", altColor)
    end

    message.setHandler("colorReplacer", colorReplacer)
    imageUpdate()
end

function colorReplacer(messageType, isLocal, color)
    storage[color.group] = color.color
    imageUpdate()
end

function imageUpdate()
    baseColor = tostring(storage.baseprimary) .. tostring(storage.basesecondary)
    animator.setPartTag(basePart, "basecolor", baseColor)
    if altPart then
        altColor = tostring(storage.altprimary) .. tostring(storage.altsecondary)
        animator.setPartTag(altPart, "altcolor", altColor)
    end

    object.setConfigParameter("baseprimary", storage.baseprimary)
    object.setConfigParameter("basesecondary", storage.basesecondary)
    if altPart then
        object.setConfigParameter("altprimary", storage.altprimary)
        object.setConfigParameter("altsecondary", storage.altsecondary)
    end
end
function primaryColor()
    local inputColor = {}
    for k, v in pairs(colorOptions.baseColors) do
        local b = paleteList.defaultColors[k]
        sb.logInfo("%s", paleteList.colors[v])
        local a = paleteList.colors[v]
        local c = {
            string.format(
                "%s%s%s%s",
                string.format("?replace;%s=%s", b[1], a[1]),
                string.format("?replace;%s=%s", b[2], a[2]),
                string.format("?replace;%s=%s", b[3], a[3]),
                string.format("?replace;%s=%s", b[4], a[4])
            )
        }
        inputColor[k] = c
        -- sb.logInfo("%s", primaryColor())
    end
    return inputColor
end
