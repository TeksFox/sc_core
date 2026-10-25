require "/scripts/vec2.lua"

local oldDndInit = init
local oldDndupdate = update
local prevPlayerPosition = {0, 0}
local playerPosition = {0, 0}

playerDefaultStats = {
    consumables = {
        cslot_1 = {},
        cslot_2 = {},
        cslot_3 = {},
        cslot_4 = {}
    },
    equipments = {
        eslot_1 = {},
        eslot_2 = {},
        eslot_3 = {},
        eslot_4 = {}
    },
    stats = {
        
    },
    abilities = {}
}
function init()
    if oldDndInit ~= nil then
        oldDndInit()
    end
    enteredBattle = nil
    battleParameter = nil
    player.setProperty("playerStatConfig", player.getProperty("playerStatConfig", playerDefaultStats))

    messages()
end

function update(dt)
    if oldDndupdate ~= nil then
        oldDndupdate(dt)
    end
    playerPosition = entity.position() or {0, 0}
    local velocity = world.distance(prevPlayerPosition, playerPosition)
    prevPlayerPosition = playerPosition

    if enteredBattle then
        for i, iPlayer in pairs(world.getObjectParameter(enteredBattle, "enteredPlayers")) do
            if iPlayer and iPlayer.id then
                local itemPosition = world.entityPosition(iPlayer.id)

                --local dist = vec2.mag(itemvec)

                local image = "/localanimator/teamborderframe.png:2"
                if battleParameter.team == iPlayer.team then
                    image = "/localanimator/teamborderframe.png:1"
                end

                local a = vec2.add(itemPosition, velocity)

                local itemvec = world.distance(vec2.add(a, {0, 0}), getPlayerPosition())

                localAnimator.addDrawable({image = image, position = itemvec, fullbright = true, centered = true})
            end
        end
    end
end

function getPlayerPosition()
    if mcontroller and mcontroller.position then
        return mcontroller.position()
    end
    return world.entityPosition(player.id()) or {0, 0}
end

function messages()
    message.setHandler(
        "placeStartBattle",
        function(_, _, _)
            world.placeObject("medievalflagpole2", world.entityPosition(entity.id()))
        end
    )
    message.setHandler(
        "enteringbattle",
        function(_, _, param)
            local config = {
                id = player.id(),
                name = player.name(),
                initiative = math.random(1, 20),
                team = tostring(math.random(1, 999))
            }
            battleParameter = config
            enteredBattle = param
            world.sendEntityMessage(param, "enterBattle", config)
        end
    )
    message.setHandler(
        "youInBattle",
        function(_, _, text)
            logInGame(text)
        end
    )
end

function logInGame(text)
    message = {
        messageId = "custom2",
        senderName = "Leia",
        portraitImage = "/interface/chatbubbles/captainrage.png:default",
        text = text,
        portraitFrames = 1,
        textSpeed = 150,
        persistTime = 5,
        portraitSpeed = 5,
        unique = false -- defaults to true
    }
    player.radioMessage(message)
end
