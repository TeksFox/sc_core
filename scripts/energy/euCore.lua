euCore = {}
local euCore = euCore
local euConfig
local euType  -- Must be one of the three: "generator", "consumer" or "storage"
local euInputNodeId  -- Id of wire input node that will be operated during energy transmission. Default - 0
local euOutputNodeId  -- Id of wire output node that will be operated during energy transmission. Default - 0
local euFromBeggining  -- Machine's starting energy capacity. Default - 0
local inputPacketOverride  -- Override input packet size to ignore euLevel formula. Default - nil
local outputPacketOverride  -- Override output packet size to ignore euLevel formula. Default - nil
-- euStorage - Maximum amount of eu that device can hold in it. Default - 10000
-- euLevel -- Defines how much energy machine maximally can input or output once per tick using formula '32 * 2^(euLevel - 1)'. lvl 1 - 32; lvl 2 - 64; lvl 3 - 128; lvl 4 - 512; lvl 5 - 2048; Default - 1
-- maxEuInputPacket -- Max packet size that consumer or storage can request. Depends on either euLevel formula or inputPacketOverride
-- maxEuOutputPacket -- Max packet size that generator or storage can answer for request. Depends on either euLevel formula or outputPacketOverride

-- LOCAL FUNCTION SIGNATURES, DEFINITIONS AT THE END
local processEuRequest
local tryRequestEu

function euCore.init(config)
	euConfig = config
	euType = euConfig.euType or ""
	energyType = euConfig.energyType or "electric"
	euInputNodeId = euConfig.euInputNodeId or 0
	euOutputNodeId = euConfig.euOutputNodeId or 0
	inputPacketOverride = euConfig.inputPacketOverride or nil
	outputPacketOverride = euConfig.outputPacketOverride or nil
	euFromBeggining = euConfig.euFromBeggining or 0
	storage.euLevel = storage.euLevel or 1
	storage.currentEu = storage.currentEu or euFromBeggining or 0
	storage.euPerTick = storage.euPerTick or euConfig.euPerTick or 0
	storage.euStorage = storage.euStorage or euConfig.euStorage or 10000

	storage.maxEuInputPacket = storage.maxEuInputPacket or inputPacketOverride or (4 * 2 ^ (storage.euLevel - 1))
	storage.maxEuOutputPacket = storage.maxEuOutputPacket or outputPacketOverride or (4 * 2 ^ (storage.euLevel - 1))

	if euType == "generator" and object.outputNodeCount() <= 0 then
		error("Generator '" .. config.getParameter("objectName", "?") .. "' must have at least one output wire node")
	elseif euType == "consumer" and object.inputNodeCount() <= 0 then
		error("Consumer '" .. config.getParameter("objectName", "?") .. "' must have at least one input wire node")
	elseif euType == "storage" and (object.outputNodeCount() <= 0 or object.inputNodeCount() <= 0) then
		error("Storage '" .. config.getParameter("objectName", "?") .. "' must have at least one input and one output wire node")
	end

	if euType == "generator" or euType == "storage" then
		message.setHandler("requestEu", processEuRequest)
	end
end

function euCore.update(dt)
	-- Storages and consumers always seek from where to burrow energy if their eu storage isn't full
	if euType ~= "generator" and storage.currentEu < storage.euStorage then
		tryRequestEu()
	end
	-- Generate or consume energy if said so
	if storage.euPerTick ~= 0 then
		if storage.euPerTick > 0 then
			euCore.addEu(storage.euPerTick)
		else -- euPerTick < 0 then
			euCore.consumeEu(math.abs(storage.euPerTick))
		end
	end
	object.setConfigParameter("currentEu", storage.currentEu / storage.euStorage)
	object.setConfigParameter("maximumEu", storage.euStorage)
end

function euCore.canFullyConsumeEu(amount) -- checks if the amount of eu can be fully consumed without any leftovers. true if yes, false otherwise
	local euSubstracted = math.min(amount, storage.currentEu)
	if amount - euSubstracted == 0 then
		return true
	end
	return false
end

function euCore.consumeEu(amount) -- substracts 'amount' eu from storage, returns leftover eu to consume
	local euSubstracted = math.min(amount, storage.currentEu)
	storage.currentEu = storage.currentEu - euSubstracted
	return amount - euSubstracted
end

function euCore.addEu(amount) -- adds 'amount' eu to storage, returns excess eu to add
	local euAdded = math.min(amount, storage.euStorage - storage.currentEu)
	storage.currentEu = storage.currentEu + euAdded
	return amount - euAdded
end

function euCore.setCurrentEu(amount)
	storage.currentEu = amount
end

function euCore.getCurrentEu()
	return storage.currentEu
end

function euCore.setEuPerTick(amount)
	storage.euPerTick = amount
end

function euCore.resetEuPerTick()
	storage.euPerTick = euConfig.euPerTick or 0
end

function euCore.getEuPerTick()
	return storage.euPerTick
end

function euCore.setInputPacketSize(amount)
	storage.maxEuInputPacket = amount
end

function euCore.getInputPacketSize()
	return storage.maxEuInputPacket
end

function euCore.setOutputPacketSize(amount)
	storage.maxEuOutputPacket = amount
end

function euCore.getOutputPacketSize()
	return storage.maxEuOutputPacket
end

function euCore.getStorageSize()
	return storage.euStorage
end

function euCore.setStorageSize(amount)
	storage.euStorage = amount
	storage.currentEu = math.min(storage.currentEu, amount)
end

function euCore.getEuLevel()
	return storage.euLevel
end

function euCore.setEuLevel(level, changePacketSize)
	storage.euLevel = level
	if changePacketSize == true then
		storage.maxEuOutputPacket = (4 * 2 ^ (level - 1))
		storage.maxEuInputPacket = (4 * 2 ^ (level - 1))
	end
end

processEuRequest = function(messageType, isLocal, amount) -- Answer the request for energy from storages or consumers
	local euToTransmit = math.min(storage.maxEuOutputPacket, amount)
	return euToTransmit - euCore.consumeEu(euToTransmit)
end

tryRequestEu = function()
	-- Send request for energy to connected generators or storages
	local requestAmount = math.min(storage.maxEuInputPacket, storage.euStorage - storage.currentEu)
	local connections = object.getInputNodeIds(euInputNodeId)
	for key, value in pairs(connections) do
		local energyTypeConnection = world.getObjectParameter(key, "euConfig")
		if energyTypeConnection.energyType == energyType then
			local gottenEu = 0
			local IApromise = world.sendEntityMessage(key, "requestEu", requestAmount)
			if IApromise and IApromise:finished() then
				if IApromise:succeeded() then
					gottenEu = IApromise:result()
				end
			end
			storage.currentEu = storage.currentEu + gottenEu
			requestAmount = requestAmount - gottenEu
			if (requestAmount <= 0) then
				break
			end
		end
	end
end
