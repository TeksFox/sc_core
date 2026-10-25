require "/scripts/util.lua"

function unpackObject(object, canvas)
    local item = root.itemConfig(object.name)

    if object then
        canvasDraw(canvas, getParameter(object.id, "colorizerParameter").animationParts, item.directory, object.id)
    end
end

function sphereCanvasDraw(color)
    sphereCanvas:clear()
    for i, color in pairs(color) do
        sphereCanvas:drawImage("/interface/scripted/colorgui/paletter.png:1" .. pickColor(color), {0 + (18 * (i - 1) + (1 * (i - 1))), 1})
    end
end

function canvasDraw(canvas, param, directory, id)
    canvas:clear()
    local colors = world.getObjectParameter(objectSelected.id, "objectColors")
    local level = tostring(world.getObjectParameter(id, "objectLevel", nil))
    local pos = canvas:size()
    local border = ""
    local transparency = ""

    for i, part in pairs(param) do
        if not part.noload then
            for stat, _ in pairs(part.colors) do
                local image = util.absolutePath(directory, part.partImage)
                --sb.logInfo("%s", image)
                local frame = root.assetJson(string.gsub(image, ".png", ".frames")).defaultFrames["default." .. stat]
                if level ~= nil then
                    frame = string.gsub(frame, "<level>", level)
                end
                sb.logInfo("%s", frame)
                local imageSize = root.imageSize(image .. ":" .. frame)

                local img
                local state = stateData.stat or stat
                if next(partData) then
                    if partData.name == i and playerColorizer.sliderOption.glow then
                        img = image .. ":" .. frame .. colors[i .. "_" .. state] .. drawSelect(i)
                    else
                        img = image .. ":" .. frame .. colors[i .. "_" .. stat] .. "?multiply=FFFFFF90"
                    end
                else
                    img = image .. ":" .. frame .. colors[i .. "_" .. stat]
                end

                canvas:drawImageDrawable(img, {pos[1] / 2 + 2, pos[2] / 2 + 2}, canvasScale(imageSize, pos))
            end
        end
    end
end

function drawSelect(i)
    if next(partData) and partData.name == i and playerColorizer.sliderOption.glow then
        return "?border=1;FFFFFF"
    end
    return ""
end

function stateDraw(stat)
    return
end

function canvasScale(img, canv)
    local scale = 5

    for i = 0, 1 do
        repeat
            scale = scale - 0.1
        until img[1] * scale <= canv[1] - 10 and img[2] * scale <= canv[2] - 10
    end

    return scale
end
