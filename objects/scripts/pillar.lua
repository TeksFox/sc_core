function init()
    storage.active = storage.active or false
    config = root.itemConfig(object.name()).config.scriptValue

    object.setInteractive(true)
    timer = config.timer
end

function update(dt)
    timer = timer - dt
    if timer <= 0 then
        local entities =
            world.entityQuery(
            object.position(),
            config.range,
            {
                includedTypes = config.target,
                boundMode = "CollisionArea"
            }
        )
        local players = world.playerQuery(object.position(), config.range)
        if next(entities) and storage.active then
            for _, player in pairs(entities) do
                for _, effect in pairs(config.effects) do
                    world.sendEntityMessage(player, "applyStatusEffect", effect.name, effect.duration)
                end
            end
        end
    end
end

function onInteraction(args)
    if storage.active then
        storage.active = false
        animator.setAnimationState("activeState", "off")
    else
        storage.active = true
        animator.setAnimationState("activeState", "on")
    end
end
