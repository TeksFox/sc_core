require "/scripts/util.lua"
require "/scripts/interp.lua"

local SourceID

function init()
    selectedItem = nil
    primaryItem = scanItemPrimaryHand()
    if primaryItem ~= nil then
        selectedItem = primaryItem.name
    end
    forceReload = true
end

function update()
    primaryItem = scanItemPrimaryHand()

    if primaryItem ~= nil and primaryItem.name ~= selectedItem then
        selectedItem = primaryItem.name
        forceReload = true
    end
    -- body

    primaryItemExtract(primaryItem, forceReload)
    forceReload = false
end

function primaryItemExtract(item, bool)
    if item then
        if bool then
            item.parameters.primaryAbility = item.parameters.primaryAbility or {}
            local weapon = root.itemConfig(item.name)
            local level = item.parameters.level or weapon.config.level
            local rarity = item.parameters.rarity or weapon.config.rarity
            local level = item.parameters.level or weapon.config.level
            local baseDamage = item.parameters.primaryAbility.baseDps or weapon.config.primaryAbility.baseDps or 1
            local fireTime = item.parameters.primaryAbility.fireTime or weapon.config.primaryAbility.fireTime or 1
            local pCount = item.parameters.primaryAbility.projectileCount or weapon.config.primaryAbility.projectileCount or 1
            local ammoCount = item.parameters.ammoCount or weapon.config.ammoCount
            local reloadTime = item.parameters.reloadTime or weapon.config.reloadTime

            sb.logInfo("%s", fireTime)

            widget.setText("layout.rarityLabel", rarity)
            widget.setText("layout.levelLabel", "Lv." .. level)
            -- widget.setText("layout.ammoNameLabel", weapon.config.primaryAbility.ammoParameters.ammoAmount)

            widget.setImage("layout.handImage", "/interface/uiparts/handlabel.png:1")
            if weapon.config.twoHanded then
                widget.setImage("layout.handImage", "/interface/uiparts/handlabel.png:2")
            end
            widget.setText("layout.ammoNameLabel", root.itemConfig(weapon.config.ammoType).config.shortdescription)
            widget.setText("layout.dpsLabel", baseDamage)
            widget.setText("layout.damagePerShotLabel", string.format("%.1f", (baseDamage * fireTime) * level))
            widget.setText("layout.speedLabel", string.format("%.1f", 1 / fireTime))
            widget.setText("layout.multLabel", pCount)
            widget.setText("layout.ammoLabel", ammoCount)
            widget.setText("layout.reloadLabel", reloadTime)

            sb.logInfo("%s", item)
            widget.setImage("layout.objectImage", util.absolutePath(weapon.directory, weapon.config.inventoryIcon))

            widget.setFontColor("layout.rarityLabel", config.getParameter("rarity")[rarity:lower()])
        end
        widget.setVisible("layout", true)
        return
    end

    widget.setVisible("layout", false)
    -- body
end

function scanItemPrimaryHand()
    local item = player.primaryHandItem()
    if item and not item.parameters.upgrade then
        return nil
    end
    return item
end
