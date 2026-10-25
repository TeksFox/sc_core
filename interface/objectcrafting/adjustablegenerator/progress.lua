require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"

local SourceID
local maxOutput = 65536
local maxPacket = 65536

function init()
    SourceID = pane.sourceEntity()
    local object = world.getObjectParameter(SourceID, "objectName")
    local config = root.itemConfig(object)
    local image = config.config.largeImage
    image = util.absolutePath(config.directory, image)
    widget.setImage("objectImage", image)
    widget.setItemSlotItem("itemIcon", object)
   	local output = world.getObjectParameter(SourceID, "euOutput", 0)
   	local packetSize = world.getObjectParameter(SourceID, "euPacketSize", 0)
   	widget.setText("output_editor", tostring(output))
	widget.setText("packet_editor", tostring(packetSize))
end

function update()
	local batteryPercent = world.getObjectParameter(SourceID, "currentEu", 0)
	local storageSize = world.getObjectParameter(SourceID, "euStorage", 0)
	local currentEu = math.floor(batteryPercent * storageSize)
	widget.setText("euLabel", tostring(currentEu).."/"..tostring(storageSize))
    widget.setProgress("progressBar", batteryPercent)
end

function apply()
	local output = (tonumber(widget.getText("output_editor"))) or 0
	local packetSize = (tonumber(widget.getText("packet_editor"))) or 0
	if output > 0 then
		output = math.min(maxOutput, output)
	elseif output < 0 then
		output = math.max(-maxOutput, output)
	end
	if packetSize > 0 then
		packetSize = math.min(maxPacket, packetSize)
	elseif packetSize < 0 then
		packetSize = 0
	end
	widget.setText("output_editor", tostring(output))
	widget.setText("packet_editor", tostring(packetSize))
	world.sendEntityMessage(SourceID, "sendParameters", output, packetSize)
end

-- OUTPUT CALLBACK

function adjust_outputminus100()
	local newEditorValue = (tonumber(widget.getText("output_editor"))) or 0
	newEditorValue = math.max(-maxOutput, newEditorValue - 100)
	widget.setText("output_editor", tostring(newEditorValue))
end

function adjust_outputminus10()
	local newEditorValue = (tonumber(widget.getText("output_editor"))) or 0
	newEditorValue = math.max(-maxOutput, newEditorValue - 10)
	widget.setText("output_editor", tostring(newEditorValue))
end
      
function adjust_outputminus1()
	local newEditorValue = (tonumber(widget.getText("output_editor"))) or 0
	newEditorValue = math.max(-maxOutput, newEditorValue - 1)
	widget.setText("output_editor", tostring(newEditorValue))
end

function adjust_outputzero()
	widget.setText("output_editor", "0")
end

function adjust_outputplus1()
	local newEditorValue = (tonumber(widget.getText("output_editor"))) or 0
	newEditorValue = math.min(maxOutput, newEditorValue + 1)
	widget.setText("output_editor", tostring(newEditorValue))
end

function adjust_outputplus10()
	local newEditorValue = (tonumber(widget.getText("output_editor"))) or 0
	newEditorValue = math.min(maxOutput, newEditorValue + 10)
	widget.setText("output_editor", tostring(newEditorValue))
end
       
function adjust_outputplus100()
	local newEditorValue = (tonumber(widget.getText("output_editor"))) or 0
	newEditorValue = math.min(maxOutput, newEditorValue + 100)
	widget.setText("output_editor", tostring(newEditorValue))
end

-- PACKET CALLBACKS

function adjust_packetminus100()
	local newEditorValue = (tonumber(widget.getText("packet_editor"))) or 0
	newEditorValue = math.max(0, newEditorValue - 100)
	widget.setText("packet_editor", tostring(newEditorValue))
end

function adjust_packetminus10()
	local newEditorValue = (tonumber(widget.getText("packet_editor"))) or 0
	newEditorValue = math.max(0, newEditorValue - 10)
	widget.setText("packet_editor", tostring(newEditorValue))
end
      
function adjust_packetminus1()
	local newEditorValue = (tonumber(widget.getText("packet_editor"))) or 0
	newEditorValue = math.max(0, newEditorValue - 1)
	widget.setText("packet_editor", tostring(newEditorValue))
end

function adjust_packetzero()
	widget.setText("packet_editor", "0")
end

function adjust_packetplus1()
	local newEditorValue = (tonumber(widget.getText("packet_editor"))) or 0
	newEditorValue = math.min(maxPacket, newEditorValue + 1)
	widget.setText("packet_editor", tostring(newEditorValue))
end

function adjust_packetplus10()
	local newEditorValue = (tonumber(widget.getText("packet_editor"))) or 0
	newEditorValue = math.min(maxPacket, newEditorValue + 10)
	widget.setText("packet_editor", tostring(newEditorValue))
end
       
function adjust_packetplus100()
	local newEditorValue = (tonumber(widget.getText("packet_editor"))) or 0
	newEditorValue = math.min(maxPacket, newEditorValue + 100)
	widget.setText("packet_editor", tostring(newEditorValue))
end

