-- Compiled with roblox-ts v2.2.0
local BoundingBox
do
	BoundingBox = setmetatable({}, {
		__tostring = function()
			return "BoundingBox"
		end,
	})
	BoundingBox.__index = BoundingBox
	function BoundingBox.new(...)
		local self = setmetatable({}, BoundingBox)
		return self:constructor(...) or self
	end
	function BoundingBox:constructor(Position, Size)
		self.Position = Position
		self.Size = Size
		self.Min = Vector2.new(self.Position.X - self.Size.X / 2, self.Position.Y - self.Size.Y / 2)
		self.Max = Vector2.new(self.Position.X + self.Size.X / 2, self.Position.Y + self.Size.Y / 2)
	end
	function BoundingBox:Overlaps(o, expand)
		if expand == nil then
			expand = 0
		end
		local min1 = self.Min
		local max1 = self.Max
		local min2 = o.Min
		local max2 = o.Max
		local halved = expand * 0.5
		return (max1.X + halved >= min2.X - halved and max2.X + halved >= min1.X - halved) and (max1.Y + halved >= min2.Y - halved and max2.Y + halved >= min1.Y - halved)
	end
	function BoundingBox:Inside(o)
		return self.Min.X <= o.X and (self.Max.X >= o.X and (self.Min.Y <= o.Y and self.Max.Y >= o.Y))
	end
end
local function GetBoundingBoxFromMinMax(A, B)
	return BoundingBox.new(Vector2.new((A.X - B.X) / 2 + B.X, (A.Y - B.Y) / 2 + B.Y), Vector2.new(math.abs(A.X - B.X), math.abs(A.Y - B.Y)))
end
return {
	GetBoundingBoxFromMinMax = GetBoundingBoxFromMinMax,
	BoundingBox = BoundingBox,
}
