require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"
-- require "/interface/scripts/ui_Components.lua"
require "/interface/scripts/ui_tooltip.lua"

data = {
	clickTime = 0.15,
	doubleClickTime = 0
}

clickTimeRemaining = 0
doubleClickCooldown = 0

iconSizes = 60
gridTileSize = {60, 60}

showSectorMap = false
timer = 0.5
anim = 1

function init()
	self.sectorMapData = root.assetJson("/interface/scripted/worldmapui/worldsData.config")
	self.sectorData = root.assetJson("/interface/scripted/worldmapui/sectorData.config")

	self.canvas = widget.bindCanvas("canvas")

	self.canvasSize = {585, 350}
	self.drag = {x = 0, y = 0}
	self.oldMousePos = {0, 0}
	self.iconSize = 60

	self.sounds = config.getParameter("sounds")
	self.images = config.getParameter("images")
	self.tileGrid = config.getParameter("gridParameters")

	self.selected = nil
	self.selectedData = nil
	self.forceReload = true
	self.listEnabled = false
	self.buttonDown = false
	self.hover = false
	self.hoverItem = nil

	self.listItems = "layout.scroll.list"

	player.setProperty("galaxyMapPosition", player.getProperty("galaxyMapPosition", {x = (self.canvasSize[1] * 0.5), y = (self.canvasSize[2] * 0.5)}))
	player.setProperty("selectedSector", player.getProperty("selectedSector", nil))

	self.drag = player.getProperty("galaxyMapPosition", {x = (self.canvasSize[1] * 0.5), y = (self.canvasSize[2] * 0.5)})
	self.selectedSector = player.getProperty("selectedSector", nil)

	if not self.selectedSector then
		self.showSectorMap = true
	end

	canvasDrawMap()
end

function update(dt)
	canvasClear()
	canwasDrawCamera()
	canvasDrawGrid()
	canvasDrawHover()
	canvasDrawMap()
	canvasDrawSelected()

	if self.selected then
		widget.setButtonEnabled("viewSector", true)
	else
		widget.setButtonEnabled("viewSector", false)
	end
	self.forceReload = false
end

function canvasDrawMap(dt)
	if self.showSectorMap then
		sectorList()
		for i, item in pairs(self.sectorMapData) do
			self.canvas:drawImage(self.images.sectorborder, setPos(item.position), 1, "white", true)

			timer = timer - script.updateDt()
			if timer <= 0 then
				anim = anim + 1
				if anim > 5 then
					anim = 1
				end
				timer = 0.75
			end
			self.canvas:drawImage(item.icon .. ":" .. anim, setPos(item.position), 1, "white", true)
		end
		if hoverSector and not selectedSector then
		end
	else
		local lock, unlock = "/interface/scripted/worldmapui/locationmarker.png:2", "/interface/scripted/worldmapui/locationmarker.png:1"
		local data = root.assetJson(self.selectedData.data)
		local pos_x = setPos(self.selectedData.position)[1]
		local pos_y = setPos(self.selectedData.position)[2]
		for i, conf in pairs(data.sectorImageSet) do
			local image = conf[1]
			local addPos = conf[2]
			local size = conf[3]
			self.canvas:drawImage(image, {pos_x + addPos[1], pos_y + addPos[2]}, size, "white", true)
		end

		for i, location in pairs(data.locations) do
			if location.locked and player.getProperty("sc_locations", {})[location.name] or location.locked == false then
				self.canvas:drawImage(unlock, {pos_x + location.position[1], pos_y + location.position[2]}, size, "white", true)
			else
				self.canvas:drawImage(lock, {pos_x + location.position[1], pos_y + location.position[2]}, size, "white", true)
			end
		end
	end
end

function sectorListSelected(wName, wData)
	local itemList = widget.getListSelected(self.listItems)
	self.selectedData = itemList and widget.getData(string.format("%s.%s", self.listItems, itemList)) or nil

	if self.selectedData then
		self.selected = self.selectedData.name
		gotoCords(self.selectedData.position)
	end
end

function homebutton(...)
	gotoCords({0, 0})
end

function canvasDrawSelected()
	if self.selected and self.showSectorMap then
		local selectPos = {setPos(self.selectedData.position)[1] + 0.5, setPos(self.selectedData.position)[2] + 0.5}

		if self.selectedData.icons then
			local startPos = selectPos[1] - 8 - ((#self.selectedData.icons - 1) * (14 / 2))
			local endPos = (selectPos[1] + (14 * (#self.selectedData.icons - 1))) - ((#self.selectedData.icons - 1) * (14 / 2))
			local midSize = "?scalenearest=" .. math.floor((#self.selectedData.icons * 14) * 0.5) .. ";1"

			for i, name in pairs(self.selectedData.icons) do
				local xIconPos = (selectPos[1] + (14 * (i - 1))) - ((#self.selectedData.icons - 1) * (14 / 2))
				self.canvas:drawImage(self.sectorData.icons[name], {xIconPos, selectPos[2] + 44}, 1, "white", true)
			end
			self.canvas:drawImage(self.images.iconsborder .. ":start", {startPos, selectPos[2] + 40}, 1, "white", true)
			self.canvas:drawImage(self.images.iconsborder .. ":mid" .. midSize, {selectPos[1], selectPos[2] + 40}, 1, "white", true)
			self.canvas:drawImage(self.images.iconsborder .. ":end", {endPos + 8, selectPos[2] + 40}, 1, "white", true)
		end
		self.canvas:drawImage(self.images.sectorselect, {selectPos[1], selectPos[2]}, 1, "white", true)
		self.canvas:drawText(
			self.selectedData.displayName,
			{
				position = {selectPos[1], selectPos[2] - 42},
				verticalAnchor = "mid",
				horizontalAnchor = "mid"
			},
			8
		)
	end
end

function viewSector()
	if self.showSectorMap then
		self.showSectorMap = false
		widget.setText("viewSector", "Back")
		widget.setVisible("showPlanetList", false)
	else
		self.showSectorMap = true
		widget.setText("viewSector", "View")
		widget.setVisible("showPlanetList", true)
	end

	gotoCords(self.selectedData.position)
	canvasDrawMap()
end

function sectorList()
	if self.forceReload then
		widget.clearListItems(self.listItems)
		for i, item in pairs(self.sectorMapData) do
			local listWidget = widget.addListItem(self.listItems)
			local itemList = string.format("%s.%s", self.listItems, listWidget)

			widget.setImage(itemList .. ".icon", item.icon .. ":1?border=1;181824")
			widget.setText(itemList .. ".name", item.displayName)

			if item.icons and next(item.icons) then
				for i, icon in pairs(item.icons) do
					local iconWidget = config.getParameter("sectorIcons")
					local sPos = iconWidget.position[1] - (14 * #item.icons)
					iconWidget.position[1] = sPos + (14 * i)
					iconWidget.file = self.sectorData.icons[icon]

					widget.addChild(itemList, iconWidget)
				end
			end
			-- widget.setText(itemList .. ".name", root.itemConfig(item.name).config.shortdescription)
			-- widget.setText(itemList .. ".count", string.format("%s/%s", ui.getAmount(item), item.count))
			-- widget.setFontColor(itemList .. ".count", string.format("%s", ui.setColor(item)))

			widget.setData(itemList, item)
		end
	end
end

function canwasDrawCamera()
	if self.buttonDown then
		local mousePos = self.canvas:mousePosition()
		self.drag.x = self.drag.x + mousePos[1] - self.oldMousePos[1]
		self.drag.y = self.drag.y + mousePos[2] - self.oldMousePos[2]

		player.setProperty("galaxyMapPosition", self.drag)
		self.oldMousePos = mousePos
	end
end

function canvasDrawGrid()
	local gridOffset = {(self.drag.x % self.tileGrid.size[1]) + 30, (self.drag.y % self.tileGrid.size[2]) + 30}
	self.canvas:drawTiledImage(self.images.nebula, {0 + (self.drag.x / 6), 0 + (self.drag.y / 6)}, {0, 0, 2000, 2000})
	self.canvas:drawTiledImage(self.images.stars, {0 + (self.drag.x / 12), 0 + (self.drag.y / 12)}, {0, 0, 1024, 1024})
	self.canvas:drawTiledImage(self.tileGrid.image, gridOffset, {0, 0, self.canvasSize[1] + self.tileGrid.size[1], self.canvasSize[2] + self.tileGrid.size[2]})
end

function drawSectors()
end

function setPos(pos, s)
	return {(60 * pos[1]) + self.drag.x, (60 * pos[2]) + self.drag.y}
end

function positionRange(clickPos, range, str)
	if str == "x" then
		return clickPos[1] >= range[1] and clickPos[1] <= range[2]
	else
		return clickPos[2] >= range[1] and clickPos[2] <= range[2]
	end
end

function positionRangeCalc(item, str)
	if str == "x" then
		return {setPos(item.position)[1] - (self.iconSize / 2), setPos(item.position)[1] + (self.iconSize / 2)}
	else
		return {setPos(item.position)[2] - (self.iconSize / 2), setPos(item.position)[2] + (self.iconSize / 2)}
	end
end

function canvasDrawHover()
	if self.showSectorMap then
		local mousePos = self.canvas:mousePosition()
		if not self.hover then
			for i, item in pairs(self.sectorMapData) do
				if positionRange(mousePos, positionRangeCalc(item, "x"), "x") and positionRange(mousePos, positionRangeCalc(item, "y"), "y") then
					if item.name ~= self.selected then
						pane.playSound(self.sounds.locationHover)
						self.hover = true
						self.hoverItem = item
						break
					end
				end
			end
		else
			if positionRange(mousePos, positionRangeCalc(self.hoverItem, "x"), "x") and positionRange(mousePos, positionRangeCalc(self.hoverItem, "y"), "y") then
				self.canvas:drawImage(self.images.sectorhover, {setPos(self.hoverItem.position)[1] + 0.5, setPos(self.hoverItem.position)[2] + 0.5}, 1, "white", true)
			else
				self.hoverItem = nil
				self.hover = false
			end
		end
	end
end

function leftClick(clickPos)
	local clicked = nil
	for i, item in pairs(self.sectorMapData) do
		if positionRange(clickPos, positionRangeCalc(item, "x"), "x") and positionRange(clickPos, positionRangeCalc(item, "y"), "y") then
			sb.logInfo("aaa %s clicPos ==== %s yRange", clickPos, yRange)
			sb.logInfo("bbb")
			if self.showSectorMap then
				pane.playSound(self.sounds.select)
				self.selectedData = item
				clicked = item.name
				canvasDrawHover()
				break
			end
		else
			clicked = self.selected
		end
	end

	if isDouble then
		if self.selected == clicked then
		else
			self.selected = clicked
			doubleClickCooldown = data.doubleClickTime
		end
	else
		if clicked then
			doubleClickCooldown = data.doubleClickTime
		end
		self.selected = clicked
	end
end

function canvasClickEvent(position, button, isButtonDown)
	if button == 0 then
		self.oldMousePos = position
		self.buttonDown = isButtonDown
		if isButtonDown then
			clickTimeRemaining = data.clickTime
		elseif clickTimeRemaining > 0 then
			clickTimeRemaining = 0

			local isDouble = doubleClickCooldown > 0 and math.abs(position[1] - lastClickPos[1]) <= 1 and math.abs(position[2] - lastClickPos[2])
			leftClick(position, isDouble)

			lastClickPos = {position[1], position[2]}
		end
	end
	if button == 2 and self.showSectorMap and self.selected then
		pane.playSound(self.sounds.deselect)
		self.selected = nil
		canvasDrawMap()
	end
end

function goToSelected(wName, wData)
	self.buttonDown = false
	if self.selectedData then
		gotoCords(self.selectedData.position)
	end
end

function showPlanetList(wName, wData)
	local bImage = "/interface/scripted/worldmapui/leftButton.png"
	local bPos = widget.getPosition(wName)
	if not self.listEnabled then
		self.listEnabled = true
		self.forceReload = true

		widget.setPosition(wName, {388, 185})
		widget.setVisible("layout", true)
		widget.setPosition("viewSector", {165, 44})
		widget.setPosition("viewSectorBack", {77, 44})
		widget.setButtonImages(
			wName,
			{
				base = bImage .. ":3",
				hover = bImage .. ":4",
				pressed = bImage .. ":4"
			}
		)
		widget.setData(wName, wData)
	else
		self.listEnabled = false

		widget.setPosition(wName, {574, 185})
		widget.setVisible("layout", false)
		widget.setPosition("viewSector", {257, 44})
		widget.setPosition("viewSectorBack", {169, 44})
		widget.setButtonImages(
			wName,
			{
				base = bImage .. ":1",
				hover = bImage .. ":2",
				pressed = bImage .. ":2"
			}
		)
		widget.setData(wName, wData)
	end

	canvasDrawMap()
end

function gotoCords(pos)
	if self.listEnabled then
		self.drag.x = (self.drag.x + (math.floor(self.canvasSize[1] * 0.5) - pos[1] * 60 - self.drag.x) - 92.5)
		self.drag.y = self.drag.y + (math.floor(self.canvasSize[2] * 0.5) - pos[2] * 60 - self.drag.y)
	else
		self.drag.x = self.drag.x + (math.floor(self.canvasSize[1] * 0.5) - pos[1] * 60 - self.drag.x)
		self.drag.y = self.drag.y + (math.floor(self.canvasSize[2] * 0.5) - pos[2] * 60 - self.drag.y)
	end
	canvasDrawMap()
end

function teleport(widgetName)
	player.warp("InstanceWorld:" .. widget.getData("layout." .. widgetName).teleport, "beam")
end

function uninit(...)
end

function createTooltip(screenPosition)
	return tooltips.creation(screenPosition)
end

function canvasClear()
	self.canvas:clear()
end
