require "/scripts/util.lua"

builder = {}

function builder.itemInit(config, directory, rarity, iConf)
    config.shortdescription = builder.namecolor(config.shortdescription, rarity, iConf)

    config.tooltipFields.rarityTitleLabel = builder.rarity(rarity, iConf)
    if config.largeImage then
        config.tooltipFields.objectImage = util.absolutePath(directory, config.largeImage) .. "?border=1;181824;"
    else
        config.tooltipFields.objectImage = util.absolutePath(directory, config.inventoryIcon) .. "?replace;000=181824"
    end
end

function builder.rarity(rarity, iConf)
    return "^" .. iConf.colors[string.lower(rarity)] .. ";" .. iConf.rarity[string.lower(rarity)]
end

function builder.namecolor(text, rarity, iConf)
    return "^" .. iConf.colors[string.lower(rarity)] .. ";" .. text
end

function builder.icon(icon, image)
    if image then
        return image .. "?border=1;181824;"
    else
        return icon .. "?replace;000000=181824"
    end
end
