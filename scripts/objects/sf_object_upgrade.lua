require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/objects/sf_object_utils.lua"
oldinitupgrade = init
olduninitupgrade = uninit

function init(...)
    if oldinitupgrade ~= nil then
        oldinitupgrade()
    end
    storage.object = nil
    message.setHandler(
        "upgrade",
        function(_, _)
            storage.object = {
                name = config.getParameter("upgrade").upgradeobject,
                position = object.position(),
                direction = object.direction(),
                parameters = storage.parameters
            }
            animator.burstParticleEmitter("upgrade")
            world.breakObject(entity.id(), true)
        end
    )
end

function uninit(...)
    if olduninitupgrade ~= nil then
        olduninitupgrade()
    end

    if storage.object ~= nil then
        world.placeObject(storage.object.name, storage.object.position, storage.object.direction)
    end
end
