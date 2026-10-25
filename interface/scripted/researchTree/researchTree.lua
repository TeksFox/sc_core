require("/scripts/ztarbound/zb_util.lua")
require("/scripts/util.lua")

-- constants
currencyTable = {}
researchTree = nil
gridTileImage = nil
gridTileSize = {}
canvasSize = nil
verified = false
canvas = nil
data = nil

-- variables
searchListRepopulationCooldown = 0
dragOffset = {x = 0, y = 0}
doubleClickCooldown = 0
idleRedrawCooldown = 0
clickTimeRemaining = 0
oldMousePos = {0, 0}
lastClickPos = {0, 0}
lowQuality = false
selectedTree = nil
mouseDown = false
panningTo = nil
readOnly = false
selected = nil
noCost = false
treeSelectedName = nil

-- Basic GUI functions
function init()

	currencyTable = root.assetJson("/currencies.config")
	data = root.assetJson("/interface/scripted/researchTree/data.config")
	for _, file in ipairs(data.researchFiles) do
		local temp = root.assetJson("/interface/scripted/researchTree/researchData/" .. file .. ".config")
		data = zbutil.MergeTable(data, temp)
	end
	widget.setOptionEnabled("setList", 2, false)
	widget.setOptionEnabled("setList", 3, false)

	gridTileImage = data.defaultGridTileImage
	gridTileSize = root.imageSize(gridTileImage)
	canvas = widget.bindCanvas("canvas")
	canvasSize = widget.getSize("canvas")

	verified = verifyAcronims()
	if not verified then
		return
	end

	for _, file in ipairs(data.externalScripts) do
		require(file)
	end

	-- Set middle of screen to canvases 0;0
	dragOffset.x = math.floor(canvasSize[1] * 0.5)
	dragOffset.y = math.floor(canvasSize[2] * 0.5)

	-- Research things that should be initially researched
	local researchedTable = player.getProperty("zb_researchtree_researched", {}) or {}
	for tree, tbl in pairs(data.initiallyResearched) do
		if not researchedTable[tree] then
			researchedTable[tree] = ""
		end

		for _, acr in ipairs(tbl) do
			if not string.find(researchedTable[tree], acr .. ",") then
				researchedTable[tree] = researchedTable[tree] .. acr .. ","
				if type(data.researchTree[tree][data.acronyms[tree][acr]].unlocks) == "table" then
					for _, blueprint in ipairs(data.researchTree[tree][data.acronyms[tree][acr]].unlocks) do
						player.giveBlueprint(blueprint)
					end
				elseif data.researchTree[tree][data.acronyms[tree][acr]].unlocks then
					player.giveBlueprint(data.researchTree[tree][data.acronyms[tree][acr]].unlocks)
				end

				if data.researchTree[tree][data.acronyms[tree][acr]].func then
					if _ENV[data.researchTree[tree][data.acronyms[tree][acr]].func] then
						_ENV[data.researchTree[tree][data.acronyms[tree][acr]].func](data.researchTree[tree][data.acronyms[tree][acr]].params)
					end
				end
			end
		end
	end

	-- Check if the tree was updated, and reaquire blueprints for already learned research
	for tree, dataString in pairs(researchedTable) do
		if data.versions[tree] then
			local oldVersion = ""

			local versionEndPos = string.find(dataString, data.versionSplitString)
			if versionEndPos then
				oldVersion = string.sub(dataString, 0, versionEndPos - 1)
			end

			if oldVersion ~= data.versions[tree] then
				if versionEndPos then
					dataString = string.sub(dataString, versionEndPos + string.len(data.versionSplitString), string.len(dataString))
				end

				local researches = stringToAcronyms(dataString)
				for i, acr in ipairs(researches) do
					local acronymTest = data.acronyms[tree][acr]
					local unlockType

					-- Check whether there's data for the acronym, and then if it has tree data.
					if acronymTest and data.researchTree[tree][acronymTest] then
						unlockType = type(data.researchTree[tree][acronymTest].unlocks)
					end

					-- Remove acronyms that don't have a linked research
					-- Otherwise relearn relevant blueprints
					if not unlockType then
						if i == 1 then
							dataString = string.gsub(dataString, acr .. ",", "")
						else
							dataString = string.gsub(dataString, "," .. acr .. ",", ",")
						end
					elseif unlockType == "table" then
						for _, blueprint in ipairs(data.researchTree[tree][data.acronyms[tree][acr]].unlocks) do
							player.giveBlueprint(blueprint)
						end
					elseif unlockType == "string" then
						player.giveBlueprint(data.researchTree[tree][data.acronyms[tree][acr]].unlocks)
					end
				end
				researchedTable[tree] = data.versions[tree] .. data.versionSplitString .. dataString
			end
		end
	end

	player.setProperty("zb_researchtree_researched", researchedTable)

	setList()
	draw()
	updateInfoPanel()
end

function update(dt)
	if not verified then
		return
	end
	

	if panningTo then
		if mouseDown then
			panningTo = nil
		else
			pan()
		end
	end

	if player.isAdmin() then
		widget.setVisible("cheatBox", true)
	else
		widget.setText("cheatBox", "")
		widget.setVisible("cheatBox", false)
	end

	-- function createTooltip(screenPosition)
	-- 	local tooltips = config.getParameter("tooltips")
	-- 	tooltips.text.value = string.format("%s", widget.getChildAt(screenPosition))
	-- 	return tooltips
	-- 	-- body
	-- end

	if selected and not readOnly and researchTree[selected].state == "available" and canAfford(selected) then
		widget.setButtonEnabled("researchButton", true)
		widget.setButtonEnabled("consumptionText", true)
	else
		widget.setButtonEnabled("researchButton", false)
		widget.setButtonEnabled("consumptionText", false)
	end

	if clickTimeRemaining > 0 then
		clickTimeRemaining = clickTimeRemaining - dt
	end

	if doubleClickCooldown > 0 then
		doubleClickCooldown = doubleClickCooldown - dt
	end

	if widget.active("searchList") then
		if searchListRepopulationCooldown <= 0 then
			searchListRepopulationCooldown = data.searchListRepopulationInterval
		else
			searchListRepopulationCooldown = searchListRepopulationCooldown - dt
		end
	end

	if not lowQuality then
		if mouseDown then
			local mousePos = canvas:mousePosition()
			dragOffset.x = dragOffset.x + mousePos[1] - oldMousePos[1]
			dragOffset.y = dragOffset.y + mousePos[2] - oldMousePos[2]
			oldMousePos = mousePos

			idleRedrawCooldown = data.idleRedrawInterval
			draw()
		elseif idleRedrawCooldown <= 0 then
			idleRedrawCooldown = data.idleRedrawInterval
			draw()
		else
			idleRedrawCooldown = idleRedrawCooldown - dt
		end
	end
end

function researchButton()
	if selected and researchTree[selected].state == "available" and canAfford(selected, true) then
		sb.logInfo("---")
		researchTree[selected].state = "researched"

		if type(researchTree[selected].unlocks) == "table" then
			for _, blueprint in ipairs(researchTree[selected].unlocks) do
				player.giveBlueprint(blueprint)
			end
		elseif researchTree[selected].unlocks then
			player.giveBlueprint(researchTree[selected].unlocks)
		end

		if researchTree[selected].func and _ENV[researchTree[selected].func] then
			_ENV[researchTree[selected].func](researchTree[selected].params)
		end

		local researchedTable = player.getProperty("zb_researchtree_researched", {}) or {}
		if not researchedTable[selectedTree] then
			researchedTable[selectedTree] = ""
		end

		for acr, research in pairs(data.acronyms[selectedTree]) do
			if research == selected then
				researchedTable[selectedTree] = researchedTable[selectedTree] .. acr .. ","
				player.setProperty("zb_researchtree_researched", researchedTable)
				break
			end
		end
	end

	buildStates()
	draw()
end

function centerButton()
	if not verified then
		return
	end
	if selected then
		panTo(researchTree[selected].position)
	else
		panTo()
	end
end

function searchButton()
end

function closeButton()
	pane.dismiss()
end

function updateInfoPanel()
	widget.clearListItems("unlocks")
	widget.clearListItems("priceList")
	widget.clearListItems("infoList.links")

	if selected then
		widget.setText("title", data.strings.info[1])
		widget.setText("infoList.text", data.strings.info[2])
		if data.strings.research[selected] then
			widget.setText("title", data.strings.research[selected][1])
			widget.setText("infoList.text", data.strings.research[selected][2])
		else
			widget.setText("title", selected)
			widget.setText("infoList.text", "ERROR - Missing text data for selected research")
		end

		if researchTree[selected].price then
			for i, tbl in ipairs(researchTree[selected].price) do
				local listWidget = widget.addListItem("priceList")
				local itemList = string.format("%s.%s", "priceList", listWidget)

				widget.setItemSlotItem(itemList .. ".item", {name = tbl[1], count = tbl[2]})
			end
		end

		for i, item in ipairs(researchTree[selected].unlocks) do
			local listWidget = widget.addListItem("unlocks")
			local itemList = string.format("%s.%s", "unlocks", listWidget)

			widget.setItemSlotItem(itemList .. ".item", {name = item, count = 1})
		end
		widget.setVisible("unlocks", true)

		--
		if researchTree[selected].links and next(researchTree[selected].links) then
			local researchedTable = player.getProperty("zb_researchtree_researched", {}) or {} --
			for i, item in ipairs(researchTree[selected].links) do
				for acr, _ in pairs(data.acronyms[item[1]]) do
					local i = string.find(researchedTable[item[1]], acr .. ",")

					if i then
						data.researchTree[item[1]][data.acronyms[item[1]][acr]].ready = true
					end
				end

				for _, node in pairs(item[2]) do
					local nodeData = data.researchTree[item[1]][node]

					local listWidget = widget.addListItem("infoList.links")
					local itemList = string.format("%s.%s", "infoList.links", listWidget)
					widget.setData(itemList, {tree = item[1], position = nodeData.position})
					widget.setText(itemList .. ".title", nodeData.name or "^red;ERROR NAME")

					widget.setItemSlotItem(
						itemList .. ".icon",
						{
							name = "copperbar",
							count = 1,
							parameters = {inventoryIcon = nodeData.icon}
						}
					)
					if nodeData.ready then
						widget.setImage(itemList .. ".border", "/interface/scripted/researchTree/itemborder.png:3")

						widget.setImage(itemList .. ".border", "/interface/scripted/researchTree/itemborder.png:4")
					end

					--if researchedTable[]
				end
			end
			widget.setOptionEnabled("setList", 3, true)
		else
			widget.setOptionEnabled("setList", 3, false)
		end
	end
end

function createColoredResearchList(dataResearch, sort)
	local arr = {}
	for research, tbl in pairs(dataResearch) do
		if not tbl.state or tbl.state == "unavailable" then
			table.insert(arr, {research, 3})
		elseif tbl.state == "researched" then
			table.insert(arr, {research, 4})
		elseif tbl.state == "available" then
			if canAfford(research) then
				sb.logInfo("%s", research)
				table.insert(arr, {research, 1})
			else
				table.insert(arr, {research, 2})
			end
		end
	end
	if sort then
		table.sort(
			arr,
			function(a, b)
				return a[2] < b[2]
			end
		)
	end
	return arr
end

function populateSearchList()
	widget.clearListItems("searchList.list")
	local listItem = ""
	local colors = {"#22FFFF", "#FFFF22", "#FF2222", "#22FF22"}

	if researchTree then
		local arr = createColoredResearchList(researchTree, true)

		for _, item in ipairs(arr) do
			listItem = "searchList.list." .. widget.addListItem("searchList.list")
			widget.setData(listItem, item[1])

			if data.strings.research[item[1]] then
				widget.setText(listItem .. ".title", data.strings.research[item[1]][1])
			else
				widget.setText(listItem .. ".title", item[1])
			end
			widget.setFontColor(listItem .. ".title", colors[item[2]])
			widget.setItemSlotItem(listItem .. ".icon", {name = "copperbar", count = 1, parameters = {inventoryIcon = researchTree[item[1]].icon}})
			widget.setImage(listItem .. ".border", "/interface/scripted/researchTree/itemborder.png:" .. item[2])
		end
	end
end

function forgottenResearch()
	local researchedTable = player.getProperty("zb_researchtree_researched", {}) or {}
	if selected then
		local acronyms = data.acronyms[treeSelectedName]

		for i, item in pairs(acronyms) do
			if string.find(researchedTable[treeSelectedName], i .. ",") and item == selected then
				researchedTable[treeSelectedName] = string.gsub(researchedTable[treeSelectedName], i .. ",", "")
			end
		end
	end
	player.setProperty("zb_researchtree_researched", researchedTable)

	buildStates()
	draw()
end

function populateTreeList()
	widget.clearListItems("treeList.list")

	local toSort = {}
	for tree, _ in pairs(data.researchTree) do
		local isAvailable = true

		if data.treeUnlocks[tree] then
			if data.treeUnlocks[tree].quests then
				for _, questId in ipairs(data.treeUnlocks[tree].quests) do
					if not player.hasCompletedQuest(questId) then
						isAvailable = false
						break
					end
				end
			end

			if isAvailable and data.treeUnlocks[tree].research then
				for tree, acronyms in pairs(data.treeUnlocks[tree].research) do
					if not isResearched(tree, acronyms) then
						isAvailable = false
						break
					end
				end
			end
		end

		if isAvailable then
			table.insert(toSort, {tree = tree, name = data.strings.trees[tree] or tree})
		end
	end

	local listItem = ""
	if (#toSort == 0) then
		listItem = "treeList.list." .. widget.addListItem("treeList.list")
		widget.setText(listItem .. ".title", "^red;No Trees Available")
		widget.setButtonEnabled(listItem .. ".title", false)
	else
		table.sort(
			toSort,
			function(a, b)
				return a.name:upper() < b.name:upper()
			end
		)

		for _, d in ipairs(toSort) do
			listItem = "treeList.list." .. widget.addListItem("treeList.list")

			widget.setData(listItem, d.tree)
			widget.setText(listItem .. ".title", d.name)

			if (data.treeIcons[d.tree]) then
				widget.setImage(listItem .. ".icon", data.treeIcons[d.tree])
			end
		end
	end
end

function researchSelected()
	local wdata = widget.getListSelected("searchList.list")
	if wdata then
		widget.setOptionEnabled("setList", 3, true)
		wdata = widget.getData("searchList.list." .. wdata)
		selected = wdata
		panTo(researchTree[wdata].position)
	end
end

function linkSelect(...)
	local wdata = widget.getListSelected("infoList.links")
	if wdata then
		listDataLoad(widget.getData("infoList.links." .. wdata), true)
	end
end

function treeSelected(selectWidget)
	local wdata = widget.getListSelected("treeList.list")
	if wdata then
		listDataLoad(widget.getData("treeList.list." .. wdata))
	end
end

function listDataLoad(wdataNew, pos)
	widget.setOptionEnabled("setList", 2, true)
	wdata = wdataNew.tree or wdataNew
	treeSelectedName = wdata
	if wdata then
		gridTileImage = data.cutsomGridTileImages[wdata] or data.defaultGridTileImage
		gridTileSize = root.imageSize(gridTileImage)

		buildStates(wdata)
		if pos then
			panTo(wdataNew.position)
		else
			panTo()
		end
	end
end

function qualityButton()
	if lowQuality then
		lowQuality = false
	else
		lowQuality = true
	end
end

function uninit()
end

-- Canvas functions
function draw()
	canvas:clear()

	-- Draw background
	local gridOffset = {dragOffset.x % gridTileSize[1], dragOffset.y % gridTileSize[2]}
	canvas:drawTiledImage(gridTileImage, gridOffset, {0, 0, canvasSize[1] + gridTileSize[1], canvasSize[2] + gridTileSize[2]})

	-- Draw "READ ONLY"
	if readOnly then
		canvas:drawText("READ ONLY!", {position = {57, canvasSize[2] - 2}}, 7, "#FF5E66F0")
	end

	-- Draw research nodes
	if researchTree then
		local startPoint = {0, 0}
		local endPoint = {0, 0}
		local r = 0
		-- draw tree lines
		for research, tbl in pairs(researchTree) do
			if tbl.state ~= "hidden" then
				if tbl.children and #tbl.children > 0 then
					r = r + 5

					startPoint[1] = (tbl.position[1] + dragOffset.x - 1)
					startPoint[2] = (tbl.position[2] + dragOffset.y - 1)

					local color = "#000000"
					local state = ""

					for i, child in ipairs(tbl.children) do

						endPoint[1] = (researchTree[child].position[1] + dragOffset.x - 1)
						endPoint[2] = researchTree[child].position[2] + dragOffset.y - 1

						if whithinBounds(startPoint, endPoint) then
							state = researchTree[child].state

							if state ~= "hidden" then
								if not state or state == "unavailable" then
									color = "#FF0000"
								elseif state == "researched" then
									color = "#00FF00"
								elseif state == "available" then
									if canAfford(child) then
										color = "#00FFFF"
									else
										color = "#FFFF22"
									end
								end

								local mid = ((startPoint[2]) + endPoint[2]) / 2
								canvas:drawLine({startPoint[1], startPoint[2]}, {startPoint[1], mid}, color, 6)
								canvas:drawLine({startPoint[1], mid}, {endPoint[1], mid}, color, 6)
								canvas:drawLine({endPoint[1], mid}, {endPoint[1], endPoint[2]}, color, 6)

							--canvas:drawLine(startPoint, endPoint, color, 6)
							end
						end
					end
				end
			end
		end

		-- draw icons
		for research, tbl in pairs(researchTree) do
			startPoint[1] = tbl.position[1] + dragOffset.x - (data.iconSizes * 0.5)
			startPoint[2] = tbl.position[2] + dragOffset.y - (data.iconSizes * 0.5)
			endPoint[1] = startPoint[1] + data.iconSizes
			endPoint[2] = startPoint[2] + data.iconSizes

			if whithinBounds(startPoint, endPoint) then
				if tbl.state ~= "hidden" then
					local nodeImage = "/interface/scripted/researchTree/nodeimage.png"
					local status = "lock"
					if not tbl.state or tbl.state == "unavailable" then
						status = "lock"
					elseif tbl.state == "researched" then
						status = "unlock"
					elseif tbl.state == "available" then
						if canAfford(research) then
							status = "ready"
						else
							status = "unready"
						end
					end

					if research == selected then
						canvas:drawImage(nodeImage .. ":" .. status .. ".hover", {startPoint[1] - 2, startPoint[2] - 2}, 1, color, false)
					else
						canvas:drawImage(nodeImage .. ":" .. status .. ".base", {startPoint[1] - 2, startPoint[2] - 2}, 1, color, false)
					end

					if tbl.state == "researched" then
						canvas:drawImage(tbl.icon, {startPoint[1] + 14, startPoint[2] + 14}, 1, "#FFFFFF", true)
					else
						canvas:drawImage(tbl.icon, {startPoint[1] + 14, startPoint[2] + 14}, 1, color, true)
					end
				end
			end
		end
	else
		canvas:drawText("NO RESEARCH TREE SELECTED", {position = {canvasSize[1] * 0.5, canvasSize[2] * 0.5}, horizontalAnchor = "mid", verticalAnchor = "mid"}, 20, "#181E24")
	end

	-- Draw currencies
	local mousePosition = canvas:mousePosition()
	for i, tbl in ipairs(data.currencies) do
		if not tbl[5] or player.currency(tbl[1]) > 0 then
			startPoint = {3, canvasSize[2] - ((i - 1) * 11 + 11)}

			canvas:drawImage(tbl[4], startPoint, 1, "#FFFFFF", false)

			if mousePosition[1] >= startPoint[1] - 1 and mousePosition[1] <= startPoint[1] + 8 and mousePosition[2] >= startPoint[2] - 1 and mousePosition[2] <= startPoint[2] + 8 then
				if tbl[1] == "essence" then
					canvas:drawText("Essence", {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
				elseif tbl[1] == "money" then
					canvas:drawText("Pixels", {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
				else
					canvas:drawText(data.strings.currencies[tbl[1]] or tbl[1], {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
				end
			else
				canvas:drawText(player.currency(tbl[1]), {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
			end
		end
	end
end

function pan()
	if not panningTo then
		return
	end

	if lowQuality then
		dragOffset.x = math.floor(canvasSize[1] * 0.5) - panningTo[1]
		dragOffset.y = math.floor(canvasSize[2] * 0.5) - panningTo[2]
	else
		dragOffset.x = dragOffset.x + ((math.floor(canvasSize[1] * 0.5) - panningTo[1] - dragOffset.x) * 0.06)
		dragOffset.y = dragOffset.y + ((math.floor(canvasSize[2] * 0.5) - panningTo[2] - dragOffset.y) * 0.06)
	end

	draw()
end

function panTo(pos)
	mouseDown = false
	if pos then
		panningTo = pos
	else
		panningTo = {0, 0}
	end
end

function whithinBounds(startPoint, endPoint)
	local xPass = false
	local yPass = false

	if startPoint[1] > 0 and startPoint[1] < canvasSize[1] then
		xPass = true
	elseif endPoint[1] > 0 and endPoint[1] < canvasSize[1] then
		xPass = true
	elseif startPoint[1] == 0 or endPoint[1] == canvasSize[1] then
		xPass = true
	elseif endPoint[1] == 0 or startPoint[1] == canvasSize[1] then
		xPass = true
	end

	if startPoint[2] > 0 and startPoint[2] < canvasSize[2] then
		yPass = true
	elseif endPoint[2] > 0 and endPoint[2] < canvasSize[2] then
		yPass = true
	elseif startPoint[2] == 0 or endPoint[2] == canvasSize[2] then
		yPass = true
	elseif endPoint[2] == 0 or startPoint[2] == canvasSize[2] then
		yPass = true
	end

	if xPass and yPass then
		return true
	end

	if yPass then
		if startPoint[1] < 0 and endPoint[1] > canvasSize[1] then
			return true
		elseif endPoint[1] < 0 and startPoint[1] > canvasSize[1] then
			return true
		end
	end

	if xPass then
		if startPoint[2] < 0 and endPoint[2] > canvasSize[2] then
			return true
		elseif endPoint[2] < 0 and startPoint[2] > canvasSize[2] then
			return true
		end
	end

	if startPoint[1] < 0 and startPoint[2] < 0 then
		if endPoint[1] > 0 and endPoint[2] > 0 then
			return true
		end
	elseif endPoint[1] < 0 and endPoint[2] < 0 then
		if startPoint[1] > 0 and startPoint[2] > 0 then
			return true
		end
	end

	if startPoint[1] < 0 and startPoint[2] > canvasSize[2] then
		if endPoint[1] > 0 and endPoint[2] < canvasSize[2] then
			return true
		end
	elseif endPoint[1] < 0 and endPoint[2] > canvasSize[2] then
		if startPoint[1] > 0 and startPoint[2] < canvasSize[2] then
			return true
		end
	end

	return false
end

function canvasClickEvent(position, button, isButtonDown)
	if not verified then
		return
	end
	if button == 0 then
		mouseDown = isButtonDown
		oldMousePos = position

		if isButtonDown then
			clickTimeRemaining = data.clickTime
		elseif clickTimeRemaining > 0 then
			clickTimeRemaining = 0

			local isDouble = doubleClickCooldown > 0 and math.abs(position[1] - lastClickPos[1]) <= 1 and math.abs(position[2] - lastClickPos[2])
			leftClick(position, isDouble)

			lastClickPos = {position[1], position[2]}
		elseif lowQuality then
			draw()
		end
	end
end

function leftClick(clickPos, isDouble)
	local xRange = {}
	local yRange = {}
	local clicked = nil

	if researchTree then
		for research, tbl in pairs(researchTree) do
			xRange = {tbl.position[1] + dragOffset.x - (data.iconSizes * 0.5) - 1, tbl.position[1] + dragOffset.x + (data.iconSizes * 0.5) + 1}
			if clickPos[1] > xRange[1] and clickPos[1] < xRange[2] then
				yRange = {tbl.position[2] + dragOffset.y - (data.iconSizes * 0.5) - 1, tbl.position[2] + dragOffset.y + (data.iconSizes * 0.5) + 1}
				if clickPos[2] > yRange[1] and clickPos[2] < yRange[2] then
					if tbl.state ~= "hidden" then
						clicked = research
					end
					break
				end
			end
		end
	end

	if isDouble then
		if selected == clicked then
			researchButton()
		else
			selected = clicked
			doubleClickCooldown = data.doubleClickTime
		end
	else
		if clicked then
			doubleClickCooldown = data.doubleClickTime
		end
		selected = clicked
	end
	updateInfoPanel()
	draw()
end

-- Research tree functions
function verifyAcronims()
	local found = false
	local missing = ""
	local tree = ""

	for t, tbl in pairs(data.researchTree) do
		tree = t
		for res1, _ in pairs(tbl) do
			found = false
			for _, res2 in pairs(data.acronyms[tree]) do
				if res1 == res2 then
					found = true
					break
				end
			end

			if not found then
				missing = missing .. "(" .. tree .. ") " .. res1 .. "\n"
			end
		end
	end

	if missing == "" then
		return true
	else
		widget.setVisible("consumptionText", false)
		widget.setVisible("treePickButton", false)
		widget.setVisible("centerButton", false)
		widget.setVisible("searchButton", false)
		widget.setText("title", "^red;ERROR:^reset; Researches missing acronyms")
		widget.setText("infoList.text", missing)
		canvas:drawLine({0, canvasSize[2] * 0.5}, {canvasSize[1], canvasSize[2] * 0.5}, "#16232BF0", canvasSize[2] * 2)
		canvas:drawText("ERROR\nMISSING ACRONYMS", {position = {canvasSize[1] * 0.5, canvasSize[2] * 0.5}, horizontalAnchor = "mid", verticalAnchor = "mid"}, 20, "#FF5E66F0")

		return false
	end
end

function stringToAcronyms(dataString)
	local splitString = {}
	local _, count = string.gsub(dataString, ",", "")
	for i = 1, count do
		splitpos = string.find(dataString, ",")
		insertingString = string.sub(dataString, 1, splitpos)
		dataString = string.gsub(dataString, insertingString, "")

		insertingString = string.gsub(insertingString, ",", "")
		table.insert(splitString, insertingString)
	end

	return splitString
end

function buildStates(tree)
	selected = nil
	if tree then
		selectedTree = tree
	elseif not selectedTree then
		return
	end

	researchTree = copy(data.researchTree[selectedTree])

	local researchedTable = player.getProperty("zb_researchtree_researched", {}) or {}
	local dataString = researchedTable[selectedTree] or ""
	local insertingString = ""
	local splitpos = 0

	local versionEndPos = string.find(dataString, data.versionSplitString)
	if versionEndPos then
		dataString = string.sub(dataString, versionEndPos + string.len(data.versionSplitString), string.len(dataString))
	end

	local splitString = stringToAcronyms(dataString)
	local isAvailable = true

	for _, acr in ipairs(splitString) do
		if data.acronyms[selectedTree][acr] and researchTree[data.acronyms[selectedTree][acr]] then
			researchTree[data.acronyms[selectedTree][acr]].state = "researched"

			if researchTree[data.acronyms[selectedTree][acr]].children then
				for _, child in ipairs(researchTree[data.acronyms[selectedTree][acr]].children) do
					if researchTree[child].state ~= "researched" then
						isAvailable = true

						for research, tbl in pairs(researchTree) do
							if research ~= data.acronyms[selectedTree][acr] and tbl.children then
								for _, child2 in ipairs(tbl.children) do
									if child2 == child and tbl.state ~= "researched" then
										isAvailable = false
										break
									end
								end
							end

							if not isAvailable then
								break
							end
						end

						if isAvailable then
							researchTree[child].state = "available"
						end
					end
				end
			end
		end
	end

	if data.hiddenResearch[selectedTree] then
		for _, acr in ipairs(data.hiddenResearch[selectedTree]) do
			if researchTree[data.acronyms[selectedTree][acr]] and not researchTree[data.acronyms[selectedTree][acr]].state then
				hideResearchBranch(data.acronyms[selectedTree][acr])
			end
		end
	end
end

function hideResearchBranch(research)
	if not researchTree[research].state then
		researchTree[research].state = "hidden"

		if researchTree[research].children then
			for _, child in ipairs(researchTree[research].children) do
				hideResearchBranch(child)
			end
		end
	end
end

function canAfford(research, consume)
	if noCost then
		return true
	end

	if researchTree[research].price then
		for _, tbl in ipairs(researchTree[research].price) do
			if currencyTable[tbl[1]] then
				if player.currency(tbl[1]) < tbl[2] then
					return false
				end
			else
				if player.hasCountOfItem(tbl[1]) < tbl[2] then
					return false
				end
			end
		end
	end

	-- Running the loops again so it consumes stuff AFTER checking that the player has everything
	if consume then
		local consumptionRules = getTreeConsumptionRules(selectedTree)
		for _, tbl in ipairs(researchTree[research].price) do
			if currencyTable[tbl[1]] then
				if consumptionRules.currency then
					player.consumeCurrency(tbl[1], tbl[2])
				end
			else
				if consumptionRules.items then
					player.consumeItem({name = tbl[1], count = tbl[2]}, true)
				end
			end
		end
	end

	return true
end

function isResearched(tree, acronym)
	local researched = player.getProperty("zb_researchtree_researched", {}) or {}

	if researched and researched[tree] then
		if type(acronym) == "string" then
			if string.match(researched[tree], acronym .. ",") then
				return true
			end
		elseif type(acronym) == "table" then
			for _, acr in ipairs(acronym) do
				if not string.match(researched[tree], acr .. ",") then
					return false
				end
			end
			return true
		end
	end

	return false
end

function getTreeConsumptionRules(tree)
	if not data.customConsumptionRules[selectedTree] then
		return {currency = true, items = true}
	end

	return {
		currency = data.customConsumptionRules[selectedTree].currency == nil or data.customConsumptionRules[selectedTree].currency == true,
		items = data.customConsumptionRules[selectedTree].items == nil or data.customConsumptionRules[selectedTree].items == true
	}
end

function setList()
	local data = widget.getSelectedData("setList").option
	widget.setVisible("searchList", false)
	widget.setVisible("infoList", false)
	widget.setVisible("treeList", false)
	if data == "searchList" then
		widget.setVisible("searchList", true)
		populateSearchList()
	elseif data == "infoList" then
		widget.setVisible("infoList", true)
		updateInfoPanel()
	elseif data == "treeList" then
		populateTreeList()
		widget.setVisible("treeList", true)
	end
end

--		Cheat codes
-- nocosttoogreat					- Toggle free researches
-- iamabeaconofknowledge			- Research everything
-- forgottenmemories				- Reset researches
-- revealourselves					- Unhides all researches
-- nostringsonme					- Disables "read only" mode
-- kotlgiffmana	[acronym string]	- Research the specified acronyms in the current research tree
-- bankrupt							- Resets all currencies displayed on the side to 0

cheats = {
	nocosttoogreat = function()
		noCost = not noCost
	end,
	iamabeaconofknowledge = function()
		local researchTable = {}
		for tree, tbl in pairs(data.acronyms) do
			if not researchTable[tree] then
				researchTable[tree] = ""
			end

			for acr, res in pairs(tbl) do
				researchTable[tree] = researchTable[tree] .. acr .. ","
				if data.researchTree[tree] and data.researchTree[tree][res] then
					if type(data.researchTree[tree][res].unlocks) == "table" then
						for _, blueprint in ipairs(data.researchTree[tree][res].unlocks) do
							player.giveBlueprint(blueprint)
						end
					elseif data.researchTree[tree][res].unlocks then
						player.giveBlueprint(data.researchTree[tree][res].unlocks)
					end

					if data.researchTree[tree][res].func then
						if _ENV[data.researchTree[tree][res].func] then
							_ENV[data.researchTree[tree][res].func](data.researchTree[tree][res].params)
						end
					end
				end
			end
		end

		player.setProperty("zb_researchtree_researched", researchTable)
		buildStates()
	end,
	forgottenmemories = function()
		player.setProperty("zb_researchtree_researched", nil)
		pane.dismiss()
		player.interact("ScriptPane", "/interface/scripted/researchTree/researchTree.ui")
	end,
	revealourselves = function()
		for _, tbl in pairs(researchTree) do
			if tbl.state == "hidden" then
				tbl.state = nil
			end
		end
	end,
	nostringsonme = function()
		readOnly = false
		widget.setText("researchButton", "Research")
		if selected and researchTree[selected].state == "available" then
			widget.setButtonEnabled("researchButton", true)
		else
			widget.setButtonEnabled(researchButton)
		end
	end,
	kotlgiffmana = function(text)
		if text and selectedTree then
			text = string.gsub(text, "kotlgiffmana ", "")
			if data.acronyms[selectedTree][text] then
				local researchedTable = player.getProperty("zb_researchtree_researched", {}) or {}
				if not researchedTable[selectedTree] then
					researchedTable[selectedTree] = ""
				end

				if data.researchTree[selectedTree] then
					if type(data.researchTree[selectedTree][data.acronyms[selectedTree][text]].unlocks) == "table" then
						for _, blueprint in ipairs(data.researchTree[selectedTree][data.acronyms[selectedTree][text]].unlocks) do
							player.giveBlueprint(blueprint)
						end
					elseif data.researchTree[selectedTree][data.acronyms[selectedTree][text]].unlocks then
						player.giveBlueprint(data.researchTree[selectedTree][data.acronyms[selectedTree][text]].unlocks)
					end

					if data.researchTree[selectedTree][data.acronyms[selectedTree][text]].func then
						if _ENV[data.researchTree[selectedTree][data.acronyms[selectedTree][text]].func] then
							_ENV[data.researchTree[selectedTree][data.acronyms[selectedTree][text]].func](data.researchTree[selectedTree][data.acronyms[selectedTree][text]].params)
						end
					end
				end

				researchedTable[selectedTree] = researchedTable[selectedTree] .. text .. ","
				player.setProperty("zb_researchtree_researched", researchedTable)
				buildStates()
			end
		end
	end,
	bankrupt = function()
		for _, tbl in ipairs(data.currencies) do
			player.consumeCurrency(tbl[1], player.currency(tbl[1]))
		end
	end
}

function cheat(wd)
	if player.isAdmin() then
		local text = widget.getText(wd)

		if string.len(text or "") > 0 then
			if cheats[text] then
				cheats[text]()
				selected = nil
			else
				local space = string.find(text, " ")
				if space then
					local word = string.sub(text, 1, space - 1)
					if cheats[word] then
						cheats[word](text)
						selected = nil
					end
				end
			end
		end

		draw()
		widget.setText(wd, "")
	end
end
