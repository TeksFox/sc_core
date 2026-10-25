require "/scripts/energy/euCore.lua"

local euCore = euCore
local euConfig
local entityID

local receiveParameters

function init()
    euConfig = config.getParameter("euConfig", "")
    euCore.init(euConfig)
    entityID = entity.id()
    message.setHandler("sendParameters", receiveParameters)
end

function update(dt)
    euCore.update(dt)
    object.setConfigParameter("euStorage", euCore.getStorageSize())

    
    if euCore.getEuPerTick() > 0 then
        animator.setAnimationState("stage", "active")
    else
        animator.setAnimationState("stage", "idle")
    end
end

receiveParameters = function(messageType, isLocal, output, packetSize)
	local newStorageSize = math.max(10000, packetSize * 4)
    euCore.setEuPerTick(output)
    euCore.setOutputPacketSize(packetSize)
    euCore.setStorageSize(newStorageSize)
    object.setConfigParameter("euOutput", output)
    object.setConfigParameter("euPacketSize", packetSize)
end