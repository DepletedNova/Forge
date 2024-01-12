-- Compiled with roblox-ts v2.2.0
local function StandardLinear(_1, _2)
	local a = _2.Y - _1.Y
	local b = -(_2.X - _1.X)
	local c = a * _1.X + b * _2.Y
	return { a, b, c }
end
local function PerpendicularLineAt(P, Q)
	local a = -Q[2]
	local b = Q[1]
	local c = a * P.X + b * P.Y
	return { a, b, c }
end
local function GetCrossingPoint(pAB, pBC)
	local A1 = pAB[1]
	local A2 = pBC[1]
	local B1 = pAB[2]
	local B2 = pBC[2]
	local C1 = pAB[3]
	local C2 = pBC[3]
	local Determinant = A1 * B2 - A2 * B1
	local DeterminantX = C1 * B2 - C2 * B1
	local DeterminantY = A1 * C2 - A2 * C1
	local x = DeterminantX / Determinant
	local y = DeterminantY / Determinant
	return Vector2.new(x, y)
end
local function GetCircumcenter(A, B, C)
	local AB = StandardLinear(A, B)
	local BC = StandardLinear(B, C)
	local mAB = A:Lerp(B, 0.5)
	local mBC = B:Lerp(C, 0.5)
	local pAB = PerpendicularLineAt(mAB, AB)
	local pBC = PerpendicularLineAt(mBC, BC)
	local circumcirle = GetCrossingPoint(pAB, pBC)
	return circumcirle
end
local Edge
do
	Edge = setmetatable({}, {
		__tostring = function()
			return "Edge"
		end,
	})
	Edge.__index = Edge
	function Edge.new(...)
		local self = setmetatable({}, Edge)
		return self:constructor(...) or self
	end
	function Edge:constructor(A, B)
		self.A = A
		self.B = B
		local _fn = math
		local _a = A
		local _b = B
		self.Distance = _fn.floor((_a - _b).Magnitude)
	end
	function Edge:Contains(compare)
		return compare == self.A or compare == self.B
	end
	function Edge:Equals(compare)
		return (compare.A == self.A and compare.B == self.B) or (compare.A == self.B and compare.B == self.A)
	end
end
local Triangle
do
	Triangle = setmetatable({}, {
		__tostring = function()
			return "Triangle"
		end,
	})
	Triangle.__index = Triangle
	function Triangle.new(...)
		local self = setmetatable({}, Triangle)
		return self:constructor(...) or self
	end
	function Triangle:constructor(p1, p2, p3)
		self.Vertexes = {}
		self.Edges = {}
		local _vertexes = self.Vertexes
		local _p1 = p1
		local _p2 = p2
		local _p3 = p3
		-- ▼ Array.push ▼
		table.insert(_vertexes, _p1)
		table.insert(_vertexes, _p2)
		table.insert(_vertexes, _p3)
		-- ▲ Array.push ▲
		local _edges = self.Edges
		local _edge = Edge.new(p1, p2)
		local _edge_1 = Edge.new(p2, p3)
		local _edge_2 = Edge.new(p3, p1)
		-- ▼ Array.push ▼
		table.insert(_edges, _edge)
		table.insert(_edges, _edge_1)
		table.insert(_edges, _edge_2)
		-- ▲ Array.push ▲
		self.Circumcenter = GetCircumcenter(p1, p2, p3)
		local _fn = math
		local _circumcenter = self.Circumcenter
		local _p1_1 = p1
		self.Circumradius = _fn.abs((_circumcenter - _p1_1).Magnitude)
	end
	function Triangle:InsideCircumcircle(point)
		local _fn = math
		local _point = point
		local _circumcenter = self.Circumcenter
		return _fn.abs((_point - _circumcenter).Magnitude) <= self.Circumradius
	end
end
return {
	Edge = Edge,
	Triangle = Triangle,
}
