-- Compiled with roblox-ts v2.2.0
local Node
do
	Node = setmetatable({}, {
		__tostring = function()
			return "Node"
		end,
	})
	Node.__index = Node
	function Node.new(...)
		local self = setmetatable({}, Node)
		return self:constructor(...) or self
	end
	function Node:constructor(Position, Cost, Previous)
		self.Position = Position
		self.Cost = Cost
		self.Previous = Previous
	end
end
return {
	Node = Node,
}
