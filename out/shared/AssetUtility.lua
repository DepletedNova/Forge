-- Compiled with roblox-ts v2.2.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local _PathUtility = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "PathUtility")
local Find = _PathUtility.Find
local WaitFor = _PathUtility.WaitFor
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Directory = WaitFor(ReplicatedStorage, "Folder", "Assets")
local function GetAsset(subsection, name)
	local subFolder = WaitFor(Directory, "Folder", subsection)
	local item = Find(subFolder, "Model", name)
	local _arg0 = item ~= nil
	assert(_arg0)
	return item
end
return {
	GetAsset = GetAsset,
}
