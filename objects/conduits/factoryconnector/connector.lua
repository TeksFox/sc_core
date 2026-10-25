require("/scripts/smarttubes/conduitscripts/st_wireless.lua")
require("/scripts/smarttubes/stCore_conduit.lua")

local oldinit = init
function init()
    ConduitCore.AddExtraPathFunction("Conduits", ExtraPathFunction)
    ConduitCore.AddExtraPathFunction("TerminalFindings", ExtraPathFunction)
    ConduitCore.SetConnectionPoints(config.getParameter("connectionpoints"))
    ConduitCore.Initialize()
    if oldinit ~= nil then
        oldinit()
    end
end

ExtraPathFunction = function()
    --if ConnectedConnections == nil then
    local Connections = Wireless.GetInputConnections()
    ConnectedConnections = {}
    if Connections ~= nil then
        for _, i in ipairs(Connections) do
            if world.getObjectParameter(i, "conduitType") == "station" then
                ConnectedConnections[#ConnectedConnections + 1] = i
            end
        end
    end
    --sb.logInfo("Nodes = " .. sb.print(ConnectedConnections) .. "for = " .. sb.print(entity.id()));
    --end
    return ConnectedConnections
end

function GetSendingConnections()
    return ExtraPathFunction()
end

OnNodeChangeFunction = function()
    --ConnectedConnections = nil;
    ExtraPathFunction()
    --sb.logInfo("Nodes Changed = " .. sb.print(entity.id()));
end
