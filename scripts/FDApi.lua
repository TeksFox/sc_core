-- FutaraDragon Api V1.1
-- Create By FutaraDragon
-- Allow people to use custom api from Futara's Dragon Engine via these function

local FDEngine = nil

-- Base Try Catch
function try(f, catch_f)
	local status, exception = pcall(f)
	if not status then
		catch_f(exception)
	end
end

-- Base Prerequire Function
function prequire(...)
    local status, lib = pcall(require, ...)
    if(status) then return status end
    return nil
end

-- Init Base Function
local oldInit = init

-- init Engine before use any custom api
function InitFDEngine()
	local Versioning = root.assetJson("/versioning.config")
	if Versioning["FutaraDragonEngine"] ~= nil then
		FDEngine = prequire("/scripts/customskill/futaradragon_util.lua")
	end
end

-- everyone can use requires for call other table directly
-- example requires("player") for access player data table
-- available table ("player","effect")
function FDRequires(DataTable)
	if(FDEngine == nil) then return end
	return requires(DataTable)
end

-- Shake The Camera
-- [Position <Vec2>] position to shake , [Radius <Number>] area effect to other people , [Momentum <Number>] how much camera shake
function FDCameraShake(Position,Radius,Momentum)
	if(FDEngine == nil) then return end
	CameraShake(Position,Radius,Momentum)
end

-- Render Dark Effect The Camera (Every things render on "FrontParticle" or higher will be front of the dark shade render)
-- [Position <Vec2>] position to query , [Radius <Number>] area effect to other people , [Power <Number 0.0 - 1.0>] How much screen will render to dark , [UpTime <Number>] Time to fade in , [Time <Number>] Time to stay , [DownTime <Number>] Time to fade in
function FDCameraDarkShade(Position,Radius,Power,UpTime,Time,DownTime)
	if(FDEngine == nil) then return end
	CameraDarkShade(Position,Radius,Power,UpTime,Time,DownTime)
end

-- Render Light Effect The Camera (Every things render on "FrontParticle" or higher will be front of the light shade render)
-- [Position <Vec2>] position to query , [Radius <Number>] area effect to other people , [Power <Number 0.0 - 1.0>] How much screen will render to light , [UpTime <Number>] Time to fade in , [Time <Number>] Time to stay , [DownTime <Number>] Time to fade in
function FDCameraLightShade(Position,Radius,Power,UpTime,Time,DownTime)
	if(FDEngine == nil) then return end
	CameraLightShade(Position,Radius,Power,UpTime,Time,DownTime)
end

-- Send and receive data betweeen object
-- for set nil value please use value "__nil"
-- for send function between object please use key "BinaryFunction"
function FDLinkData(ObjectThreadKey,ObjectThreadValue)
	if(FDEngine == nil) then return end
	if ObjectThreadValue == nil then return io.socket(ObjectThreadKey) end
	io.socket(ObjectThreadKey,ObjectThreadValue)
end

-- Save all Data to character save file (ForceSave will effect to network side but will force save all data, please use in important case; example save Character Skill)
-- [ForceSave <Bool>]
function FDSaveAllData(ForceSave)
	if(FDEngine == nil) then return end
	SaveAllData(ForceSave)
end

-- Temp all player tech and clear all tech
-- !! unstable, work in progress
--[[
function FDTechTemp()
	if(FDEngine == nil) then return end
	TechTemp()
end
]]

-- Return all temp tech back to player
-- !! unstable, work in progress
--[[
function FDTechReturn()
	if(FDEngine == nil) then return end
	TechReturn()
end
]]
