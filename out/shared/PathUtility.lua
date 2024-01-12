-- Compiled with roblox-ts v2.2.0
local function Find(Obj, ClassName, Name, Recursive)
	if Recursive == nil then
		Recursive = false
	end
	return (Obj:FindFirstChild(Name, Recursive)) or nil
end
local function FindWhichIsA(Obj, ClassName, Recursive)
	if Recursive == nil then
		Recursive = false
	end
	return (Obj:FindFirstChildWhichIsA(ClassName, Recursive)) or nil
end
local function WaitFor(Obj, ClassName, Name)
	return (Obj:WaitForChild(Name, 5)) or nil
end
return {
	Find = Find,
	FindWhichIsA = FindWhichIsA,
	WaitFor = WaitFor,
}
