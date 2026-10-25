ammo = {}

function ammo.init()
    reload = ammo.getReloadTime()
    emptyAmmo = true
    reloadStart = true

    activeItem.setInstanceValue("ammoLoadet", ammo.getAmmo())
end

function ammo.update(dt)
    if ammo.getAmmo() <= 0 then
        if not player.hasItem(ammo.getAmmoType()) then
            if emptyAmmo then
                animator.playSound("empty")
                emptyAmmo = false
            end
            activeItem.setCursor("/cursors/noammo.cursor")
            return
        else
            player.hasItem(ammo.getAmmoType())
            activeItem.setCursor("/cursors/reload.cursor")
            if reloadStart then
                
                animator.playSound("empty")
                animator.playSound("reloadStart")
                reloadStart = false
            end
            reload = reload - dt
            if reload <= 0 then
                animator.playSound("reloadEnd")
                ammo.reload(ammo.getAmmoCount(), ammo.getAmmoType())
                reloadStart = true
                emptyAmmo = true
                activeItem.setCursor("/cursors/reticle0.cursor")
            end
        end
        return
    end

    reload = ammo.getReloadTime()
end

function ammo.reload()
    local ammoCount = ammo.getAmmoCount()
    if player.hasCountOfItem(ammo.getAmmoType()) < ammo.getAmmoCount() then
        ammoCount = player.hasCountOfItem(ammo.getAmmoType())
    end
    ammo.setAmmo(ammoCount)
    player.consumeItem({ammo.getAmmoType(), ammoCount})

    return
end

function ammo.getReloadTime()
    return config.getParameter("reloadTime")
end

function ammo.getAmmoCount()
    return config.getParameter("ammoCount")
end

function ammo.getAmmoType()
    return config.getParameter("ammoType")
end

function ammo.setAmmo(ammo)
    activeItem.setInstanceValue("ammoLoadet", ammo)
end

function ammo.getAmmo()
    return config.getParameter("ammoLoadet")
end
