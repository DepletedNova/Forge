-- Compiled with roblox-ts v2.2.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local _PathUtility = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "PathUtility")
local Find = _PathUtility.Find
local WaitFor = _PathUtility.WaitFor
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = ReplicatedStorage:WaitForChild("Packets")
-- API
local function GetEvent(Name)
	local Events
	if RunService:IsClient() then
		local player = Players.LocalPlayer
		local playerScripts = WaitFor(player, "PlayerScripts", "PlayerScripts")
		local _arg0 = playerScripts ~= nil
		assert(_arg0)
		Events = WaitFor(playerScripts, "Folder", "Events")
	else
		local ServerStorage = game:GetService("ServerStorage")
		Events = WaitFor(ServerStorage, "Folder", "Events")
	end
	local _arg0 = Events ~= nil
	assert(_arg0)
	return Find(Events, "BindableEvent", Name, false)
end
-- Client
if RunService:IsClient() then
	-- Player
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(function(char)
		GetEvent("Spawn"):Fire(player, char)
		local humanoid = WaitFor(char, "Humanoid", "Humanoid")
		local _arg0 = humanoid ~= nil
		assert(_arg0)
		local deathConnection
		deathConnection = humanoid.Died:Connect(function()
			deathConnection:Disconnect()
			GetEvent("Death"):Fire(player, char)
		end)
	end)
end
-- Server
if RunService:IsServer() then
	local playerConnections = {}
	-- Players
	Players.PlayerAdded:Connect(function(player)
		GetEvent("PlayerJoin"):Fire(player)
		local charConnection = player.CharacterAdded:Connect(function(char)
			GetEvent("CharacterSpawn"):Fire(player, char)
			local humanoid = WaitFor(char, "Humanoid", "Humanoid")
			local _arg0 = humanoid ~= nil
			assert(_arg0)
			local deathConnection
			deathConnection = humanoid.Died:Connect(function()
				deathConnection:Disconnect()
				GetEvent("CharacterDeath"):Fire(player, char)
			end)
		end)
		local _arg0 = { player, charConnection }
		table.insert(playerConnections, _arg0)
	end)
	Players.PlayerRemoving:Connect(function(player)
		GetEvent("PlayerLeave"):Fire(player)
		do
			local i = 0
			local _shouldIncrement = false
			while true do
				if _shouldIncrement then
					i += 1
				else
					_shouldIncrement = true
				end
				if not (i < 0) then
					break
				end
				local connections = playerConnections[i + 1]
				if connections[1] ~= player then
					continue
				end
				connections[2]:Disconnect()
				local _i = i
				table.remove(playerConnections, _i + 1)
				break
			end
		end
	end)
end
return {
	GetEvent = GetEvent,
}
