require "/scripts/util.lua"
tooltip = {}

function tooltip.create(data)
    local config = root.assetJson("/interface/craftingtooltip/previevColorizer_tooltip.pane")
    local itemConfig = root.itemConfig(objectSelected.name)

    for i, part in pairs(data) do
        if not part.noload then
            local item = {
                type = "layout",
                layoutType = "basic",
                size = {89, 88},
                position = {19, 19},
                zlevel = 10,
                children = {}
            }
            local iConf =
                tooltip.imageColorizer(part.partImage, part.colors, itemConfig, config.previevSize)
            item.children.image = copy(config.image)
            item.children.image.file = iConf[1]
            item.children.image.scale = iConf[2][1]
            item.children.image.position = tooltip.setPosition(iConf[2])

            config.previevTooltip["item" .. i] = item
        end
    end

    return config.previevTooltip
end

function tooltip.setPosition(data)
    local image = data[2]
    local siz = data[3]

    return {(siz[1] - (image[1] * data[1])) / 2, (siz[2] - (image[2] * data[1])) / 2}
end

function tooltip.imageColorizer(img, colors, config, siz)
    local colorConfig = root.assetJson("/configs/palettes/colorizer.config")

    local arr = {}
    local fullImage = ""
    local imageSize = {}
    for stat, _ in pairs(colors) do
        local image = util.absolutePath(config.directory, img)
        local frame = root.assetJson(string.gsub(image, ".png", ".frames")).defaultFrames["default." .. stat]

        local subarr = {}
        local palette = ""
        for i = 1, #colors[stat] do
            local baseColor = colorConfig.default[i]
            local newColor = colorConfig.colors[colors[stat][i]].palette
            for c = 1, 4 do
                paletteSwaps = string.format("%s?replace=%s=%s", palette, baseColor[c], newColor[c])
                table.insert(arr, paletteSwaps)
            end
        end
        imageSize = tooltip.scale(root.imageSize(image .. ":" .. frame), siz)
        fullImage = image .. ":" .. frame
    end
    return {fullImage .. table.concat(arr), imageSize}
end

function tooltip.scale(img, siz)
    local scale = 5

    for i = 0, 1 do
        repeat
            scale = scale - 0.1
        until img[1] * scale <= siz[1] and img[2] * scale <= siz[2]
    end

    return {scale, img, siz}
end
