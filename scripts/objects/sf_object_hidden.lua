function init(...)
    storage.globalTag = storage.globalTag or "default.1"
    animator.setGlobalTag("tag", storage.globalTag)
end

function update()
    local interactive = false
    local players = world.playerQuery(object.position(), 7)
    for i, player in pairs(players) do
        local scaner = world.entityHandItemDescriptor(player, "primary")
        if scaner and scaner.name == "structurescaner" then
            interactive = true
            if config.getParameter("hideItem", true) then
                storage.globalTag = "show." .. math.random(1, config.getParameter("variants"))
                animator.setGlobalTag("tag", storage.globalTag)
                animator.setParticleEmitterActive("dust", true)
                object.setConfigParameter("hideItem", false)
            end
        end
    end

    object.setInteractive(interactive)
end

-- function onInteraction()
--     world.spawnItem({name = "copperbar", count = 10, parameters = {itemTags = {"pidoras"}}}, object.position())
--     world.breakObject(entity.id(), false)
-- end
