require("/scripts/smarttubes/stCore_server.lua");

--Variables
local ExtractionConfigBuffer;
local Data = {};
local UsingTerminal = false;

--Functions
local oldPipeInit = init;
local oldPipeUninit = uninit;


function init()
	if oldPipeInit ~= nil then
		oldPipeInit();
	end
	Server.SetDefinitionTable(Data);
	Server.DefineSyncedValues("Settings","Index",1,"Breaking",false);
	message.setHandler("SetSwapItem",function(_,_,item)
		player.setSwapSlotItem(item);
	end);
	message.setHandler("SetCopyBuffer",function(_,isLocal,config)
		--sb.logInfo("COPY BUFFER LOCAL = " .. sb.print(isLocal));
		ExtractionConfigBuffer = config;
	end);
	message.setHandler("GetCopyBuffer",function()
		return ExtractionConfigBuffer;
	end);
	message.setHandler("BufferIsSet",function(_,isLocal)
		--sb.logInfo("Buffer Is Set Local = " .. sb.print(isLocal));
		return ExtractionConfigBuffer ~= nil;
	end);
	message.setHandler("UsingTerminal",function()
		return UsingTerminal == true;
	end);
	message.setHandler("SetUsingTerminal",function(_,_,bool)
		UsingTerminal = bool == true;
	end);
end

--function TestFunction()
--	sb.logInfo("Test");
--end

function uninit()
	if oldPipeUninit ~= nil then
		oldPipeUninit();
	end
end