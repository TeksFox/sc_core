require "/scripts/vec2.lua"

require "/scripts/utils/util_image.lua"
objectUtils = {}
function objectUtils.rootJson(parameter)
    return root.assetJson(util.absolutePath(root.itemConfig(object.name()).directory, parameter))
end

function objectUtils.setColor(partName, tagName, color)
    local data = root.assetJson("/configs/colors.config")
    animator.setPartTag(partName, tagName, image.replaceColor(data.default[1], data.colors[color]))
end

function objectUtils.setProgress(partName, tagName, curr, max, rect, orientation)
    animator.setPartTag(partName, tagName, image.progress(curr, max, rect), orientation)
end
