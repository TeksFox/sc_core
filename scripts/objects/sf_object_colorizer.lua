require "/scripts/imageoperator.lua"

oldinit = init
oldupdate = update
olddie = die

function init()
    if oldinit ~= nil then
        oldinit()
    end

    storage.colorizer = storage.colorizer or {}
    storage.colorizer.parameters = storage.colorizer.parameters or config.getParameter("animationParameters")
    storage.colors = storage.colors or defaultColorizer(storage.colorizer.parameters) or {}
    setColorableParts(storage.colorizer.parameters)

    message.setHandler(
        "colorizerReplace",
        function(_, _, parameters)
            storage.colorizer.parameters.animationParts = parameters
            storage.colors = defaultColorizer(storage.colorizer.parameters)
            setColorableParts(storage.colorizer.parameters)

            object.setConfigParameter("colorizerParameter", storage.colorizer.parameters)
            object.setConfigParameter("objectColors", storage.colors)
        end
    )
    object.setConfigParameter("colorizerParameter", storage.colorizer.parameters)
    object.setConfigParameter("objectColors", storage.colors)
end

function setColorableParts(parameter)
    for part, config in pairs(parameter.animationParts) do
        animator.setPartTag(part, "part", config.partImage)
        if parameter.animationParts[part].colors then
            for state, _ in pairs(parameter.animationParts[part].colors) do
                animator.setPartTag(part, "color_" .. state, storage.colors[part .. "_" .. state])
            end
        end
    end
end

function defaultColorizer(parameter)
    local colorConfig = root.assetJson("/configs/palettes/colorizer.config")
    local arr = {}

    for part, config in pairs(parameter.animationParts) do
        if config.colors and next(config.colors) then
            for state, _ in pairs(config.colors) do
                local subarr = {}
                for i = 1, #config.colors[state] do
                    local palette = ""
                    local baseColor = colorConfig.default[i]
                    local newColor = colorConfig.colors[config.colors[state][i]].palette
                    table.insert(subarr, image.replaceColor(colorConfig.default[i], colorConfig.colors[config.colors[state][i]].palette))
                end
                arr[part .. "_" .. state] = table.concat(subarr)
            end
        end
    end
    return arr
end
