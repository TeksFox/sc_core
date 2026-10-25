cnvs = {}

local canvastile = "/interface/scripted/localanimatorgui/tile.png"
local canvas = "canvaslayout.canvas"
local clicks = {}
local cnvsPos = {0, 0}
local newPosition = {0, 0}
local mousePos = {0, 0}
function cnvs.init(canvas)
    local size = canvas:size()
    cnvsPos = {size[1] / 2, size[2] / 2}
end

function cnvs.update(canvas)
    canvas:clear()
    local size = canvas:size()
    local mPos = canvas:mousePosition()

    if click and click.button == 0 and click.isDown == true then

        local dist = 0
    else
        clicks = {}
    end

    canvas:drawTiledImage(canvastile, cnvsPos, {0, 0, size[1], size[2]})
    canvas:drawImage("/interface/scripted/localanimatorgui/barlayout.png", {cnvsPos[1] + 10, cnvsPos[2] + 10})
end

function cnvs.clickEvent(position, button, isDown)
    if widget.hasFocus("canvaslayout.canvas") then
        table.insert(clicks, {position, button, isDown})
    end
end
