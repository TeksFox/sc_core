require("/scripts/smarttubes/conduitscripts/st_wireless.lua");
require("/scripts/smarttubes/stCore_conduit.lua");

local OldInit = init
local ConnectedConnections;
local ExtraPathFunction;
local OnNodeChangeFunction;

function init()
    SourcePosition = entity.position()
    SourceID = entity.id()
    ConduitCore.Initialize()
	ConduitCore.AddExtraPathFunction("TerminalFindings",ExtraPathFunction);
	Wireless.AddNodeChangeFunction(OnNodeChangeFunction);

    if OldInit ~= nil then
        OldInit()
    end
end

ExtraPathFunction = function()
	--if ConnectedConnections == nil then
		local Connections = Wireless.GetOutputConnections();
		ConnectedConnections = {};
		if Connections ~= nil then
			for _,i in ipairs(Connections) do
				if world.getObjectParameter(i,"conduitType") == "connector" then
					ConnectedConnections[#ConnectedConnections + 1] = i;
				end
			end
		end
	--end
	return ConnectedConnections;
end

function GetReceivingConnections()
	return ExtraPathFunction();
end

--Called when the Wireless Connections are changed
OnNodeChangeFunction = function()
	ConnectedConnections = nil;
	sb.logInfo("Nodes Changed = " .. sb.print(entity.id()));
end
