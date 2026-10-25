require "/scripts/energy/euCore.lua"

local euCore = euCore

function init()
	euCore.init(config.getParameter("euConfig", ""))
end

function update(dt)
	euCore.update(dt)
end

