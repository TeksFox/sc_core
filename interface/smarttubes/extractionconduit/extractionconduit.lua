require("/scripts/smarttubes/conduitscripts/st_extractionui.lua")
require("/scripts/utils/ui_tooltip.lua")

--Variables
local OldInit = init
local OldUninit = uninit
--TEST
--local Result;

--Functions
local ConfigUpdate
local CopyBufferChange

--Initializes the Extraction Conduit UI
function init()
	widget.setButtonEnabled("pasteButton", false)
	if OldInit ~= nil then
		OldInit()
	end
	--[[local Test = coroutine.create(function(path)
        sb.logInfo("Path = " .. sb.print(path));
        Result = root.assetJson(path);
    end);
    coroutine.resume(Test,"/Blocks/Conduits/Item Conduit/Item Conduit.object");--]]
	--sb.logInfo("Result = " .. sb.print(Result));
	ExtractionUI.AddCopyBufferChangeFunction(CopyBufferChange)
	ExtractionUI.Initialize()
end

--Uninitializes the Extraction UI
function uninit()
	if OldUninit ~= nil then
		OldUninit()
	end
	ExtractionUI.Uninitialize()
end

function createTooltip(screenPosition)
	return tooltips.creation(screenPosition)

	--sb.logInfo("%s", "namename")
end

--Called when the item box is clicked
function itemBox()
	ExtractionUI.SetItemInSlot(player.swapSlotItem())
end

--Called when the item box is right clicked
function itemBoxRight()
	ExtractionUI.SetItemInSlot(nil)
end

--Called when the selected config item changes
--[[function SelectedItemChange()
	
end--]]
--Called when the player's copy buffer has changed
CopyBufferChange = function()
	widget.setButtonEnabled("pasteButton", ExtractionUI.CopyBufferIsSet())
end

--Called when the "copy" button is pressed
function Copy()
	ExtractionUI.CopyConfig(ExtractionUI.GetSelectedConfig())
	widget.setButtonEnabled("pasteButton", true)
end

--Called when the "paste" button is pressed
function Paste()
	ExtractionUI.PasteConfig()
end

--Called when the "Add" button is clicked
function Add()
	ExtractionUI.AddNewConfig()
end

--Called when the "Remove" button is clicked
function Remove()
	ExtractionUI.RemoveSelectedConfig()
end

--Called when the Up arrow button is clicked
function orderUp()
	local SelectedConfig = ExtractionUI.GetSelectedConfig()
	if ExtractionUI.MoveUpConfig(SelectedConfig) then
		ExtractionUI.SetSelectedConfig(SelectedConfig - 1)
	end
end

--Called when the Down arrow button is clicked
function orderDown()
	local SelectedConfig = ExtractionUI.GetSelectedConfig()
	if ExtractionUI.MoveDownConfig(SelectedConfig) then
		ExtractionUI.SetSelectedConfig(SelectedConfig + 1)
	end
end

--Called when the speed "plus" button is clicked
function SpeedAdd()
	local MaxSpeed = ExtractionUI.GetUISettings().MaxSpeed
	local CurrentSpeed = ExtractionUI.GetSpeed()
	if CurrentSpeed < MaxSpeed and player.consumeItem({name = "speedupgrade", count = 1}) ~= nil then
		ExtractionUI.SetSpeed(CurrentSpeed + 1)
	end
end

--Called when the speed "minus" button is clicked
function SpeedRemove()
	local CurrentSpeed = ExtractionUI.GetSpeed()
	if CurrentSpeed > 0 then
		player.giveItem({name = "speedupgrade", count = 1})
		ExtractionUI.SetSpeed(CurrentSpeed - 1)
	end
end

--Called when the stack "plus" button is clicked
function StackAdd()
	local MaxStack = ExtractionUI.GetUISettings().MaxStack
	local CurrentStack = ExtractionUI.GetStack()
	if CurrentStack < MaxStack and player.consumeItem({name = "stackupgrade", count = 1}) ~= nil then
		ExtractionUI.SetStack(CurrentStack + 1)
	end
end

--Called when the stack "minus" button is clicked
function StackRemove()
	local CurrentStack = ExtractionUI.GetStack()
	if CurrentStack > 0 then
		player.giveItem({name = "stackupgrade", count = 1})
		ExtractionUI.SetStack(CurrentStack - 1)
	end
end

--Called when the edit button is pressed
function Edit()
	if ExtractionUI.SetTextToConfig(ExtractionUI.GetSelectedConfig()) then
		ExtractionUI.RemoveSelectedConfig()
	end
end

--Called when the "save settings" button is pressed
function Save()
	world.sendEntityMessage(ExtractionUI.GetSourceID(), "Extraction.SaveParameters", world.entityPosition(player.id()))
end

--Called when the "right" color button is clicked
function ColorIncrement()
	ExtractionUI.IncrementColor()
end

--Called when the Conduit's name textbox is changed
function ConduitNameChange()
	world.sendEntityMessage(ExtractionUI.GetSourceID(), "SetUISaveName", widget.getText("conduitNameBox"))
end

--Called when the "left" color button is clicked
function ColorDecrement()
	ExtractionUI.DecrementColor()
end

--Called when the text in the search box has changed
function SearchChange()
	ExtractionUI.SetSearchKeyword(widget.getText("searchBox") or "")
end

function insertIntoSlotHelp()
	ExtractionUI.SetHelpText("          ")
end

function searchHelp()
	ExtractionUI.SetHelpText("           Search Box \n\nUsed for searching for the config you want")
end
