local oldinit = init

function init()
	if oldinit ~= nil then
		oldinit()
	end
	object.setInteractive(true)
	object.setConfigParameter("RetainingParameters", {"Speed", "Stack", "SelectedColor", "Configs", "insertID"})
end

local oldUpdate = update

function update(dt)
	if oldUpdate ~= nil then
		oldUpdate(dt)
	end
end

local FinalJson = nil
function onInteraction(args)
	if FinalJson == nil then
		local Scripts = {}
		local Callbacks = {}
		local ExtractionJson = root.assetJson("/interface/smarttubes/extractionconduit/extractionconduit.ui")
		if ExtractionJson.scripts ~= nil then
			for k, i in ipairs(ExtractionJson.scripts) do
				Scripts[#Scripts + 1] = i
			end
		end
		if ExtractionJson.scriptWidgetCallbacks ~= nil then
			for k, i in ipairs(ExtractionJson.scriptWidgetCallbacks) do
				Callbacks[#Callbacks + 1] = i
			end
		end
		local InsertionPatch = root.assetJson("/interface/smarttubes/ioconduit/ioconduit.ui")
		if InsertionPatch.scripts ~= nil then
			for k, i in ipairs(InsertionPatch.scripts) do
				Scripts[#Scripts + 1] = i
			end
		end
		if InsertionPatch.scriptWidgetCallbacks ~= nil then
			for k, i in ipairs(InsertionPatch.scriptWidgetCallbacks) do
				Callbacks[#Callbacks + 1] = i
			end
		end
		FinalJson = sb.jsonMerge(ExtractionJson, InsertionPatch)
		FinalJson.scripts = Scripts
		FinalJson.scriptWidgetCallbacks = Callbacks
		FinalJson.gui.windowtitle.title = ""
		--DPrint("OriginalDescription = " .. sb.print(config.getParameter("OriginalDescription")));
		FinalJson.gui.conduitNameBox.hint = config.getParameter("OriginalDescription") or config.getParameter("shortdescription", "IO Conduit")
		FinalJson.gui.windowtitle.subtitle = "Extracts and inserts into inventories"
	end
	return {"ScriptPane", FinalJson}
end
