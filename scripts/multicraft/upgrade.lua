
require "/scripts/energy/euCore.lua"

function init()
    levelconfig = config.getParameter("levelConfig", nil)

    storage.eMultipler = storage.eMultipler or (lConfig.eMultipler or 0) * (storage.level - 1)
    storage.cMultipler = storage.cMultipler or (lConfig.cMultipler or 0) * (storage.level - 1)
    storage.sMultipler = storage.sMultipler or (lConfig.sMultipler or 0) * (storage.level - 1)

    storage.recipeLevel = storage.recipeLevel or storage.level


    euCore.setStorageSize(
        (euConfig.euStorage + storage.battaryBonus) * (1 + ((storage.eMultipler) * (storage.level - 1)))
    )
end
