require "/scripts/vec2.lua"
require "/scripts/util.lua"
objectUtils = {}

function objectUtils.rootJson(parameter)
    return root.assetJson(util.absolutePath(root.itemConfig(object.name()).directory, parameter))
end
