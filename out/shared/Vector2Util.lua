-- Compiled with roblox-ts v2.2.0
local function RoundVector2(a)
	return Vector2.new(math.round(a.X), math.round(a.Y))
end
local function Vector2String(a)
	return tostring(tostring(math.round(a.X)) .. ", " .. tostring(math.round(a.Y)))
end
return {
	RoundVector2 = RoundVector2,
	Vector2String = Vector2String,
}
