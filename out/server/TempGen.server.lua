-- Compiled with roblox-ts v2.2.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local _BoundingBox = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Generation", "BoundingBox")
local BoundingBox = _BoundingBox.BoundingBox
local GetBoundingBoxFromMinMax = _BoundingBox.GetBoundingBoxFromMinMax
local _Polygons = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Generation", "Polygons")
local Edge = _Polygons.Edge
local Triangle = _Polygons.Triangle
local Node = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Generation", "Node").Node
local _Vector2Util = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Vector2Util")
local RoundVector2 = _Vector2Util.RoundVector2
local Vector2String = _Vector2Util.Vector2String
local ROOM_COUNT = 5
local MAX_TRIES = 10
local MINIMUM_SPACING = 3
local ARENA_SIZE = 50
local SPAWN = BoundingBox.new(Vector2.zero, Vector2.new(5, 5))
local ROOM_SIZE = Vector2.new(5, 5)
local SHOW_CIRCUMCIRCLES = true
-- temp visuals
local BeamPart = Instance.new("Part")
BeamPart.Anchored = true
BeamPart.Parent = game.Workspace
BeamPart.Size = Vector3.one
BeamPart.Transparency = 1
BeamPart.Position = Vector3.zero
local lastAttachment
local function BuildBeam(Pos, detected)
	if detected == nil then
		detected = false
	end
	local attachment = Instance.new("Attachment")
	attachment.Parent = BeamPart
	attachment.CFrame = CFrame.new(Vector3.new(Pos.X, if detected then 0.5 else 0, Pos.Y))
	if lastAttachment ~= nil then
		local beam = Instance.new("Beam")
		beam.Attachment0 = lastAttachment
		beam.Attachment1 = attachment
		beam.Parent = BeamPart
		beam.FaceCamera = true
		if detected then
			beam.Color = ColorSequence.new(Color3.new(1, 0, 0))
		end
	end
	lastAttachment = attachment
end
local Triangles = {}
local function RebuildBeams(polygons, clear)
	if polygons == nil then
		polygons = {}
	end
	if clear == nil then
		clear = true
	end
	if clear then
		BeamPart:ClearAllChildren()
	end
	for _, tri in Triangles do
		lastAttachment = nil
		for _1, vertex in tri.Vertexes do
			BuildBeam(vertex)
		end
		BuildBeam(tri.Vertexes[1])
		if SHOW_CIRCUMCIRCLES then
			local circle = Instance.new("Part")
			circle.Anchored = true
			circle.Parent = BeamPart
			circle.Size = Vector3.one
			circle.Transparency = 0.95
			circle.Position = Vector3.new(tri.Circumcenter.X, 0, tri.Circumcenter.Y)
			circle.Rotation = Vector3.new(0, 0, 90)
			local mesh = Instance.new("SpecialMesh")
			mesh.Parent = circle
			mesh.MeshType = Enum.MeshType.Cylinder
			mesh.Scale = Vector3.new(0.5, tri.Circumradius * 2, tri.Circumradius * 2)
		end
	end
	for _, poly in polygons do
		lastAttachment = nil
		BuildBeam(poly.A, clear)
		BuildBeam(poly.B, clear)
	end
end
-- Random room placement
local Rooms = { SPAWN }
local RoomSpawning = ROOM_COUNT
do
	local i = 0
	local _shouldIncrement = false
	while true do
		if _shouldIncrement then
			i += 1
		else
			_shouldIncrement = true
		end
		if not (i < ROOM_COUNT) then
			break
		end
		-- Multi-threaded room placement
		spawn(function()
			-- Limit number of tries
			do
				local currentTry = 0
				local _shouldIncrement_1 = false
				while true do
					if _shouldIncrement_1 then
						currentTry += 1
					else
						_shouldIncrement_1 = true
					end
					if not (currentTry < MAX_TRIES) then
						break
					end
					-- Grab a random position to place a room
					local box = BoundingBox.new(Vector2.new(math.random(ARENA_SIZE) - ARENA_SIZE / 2, math.random(ARENA_SIZE) - ARENA_SIZE / 2), ROOM_SIZE)
					-- Check if rooms overlap with any other or spawn room
					local result = false
					for _, room in Rooms do
						local _condition = result
						if not result then
							_condition = room:Overlaps(box, MINIMUM_SPACING)
						end
						result = _condition
					end
					--result ||= SPAWN.Overlaps(box, MINIMUM_SPACING);
					-- if rooms do not overlap skip other tries and place the room
					if not result then
						table.insert(Rooms, box)
						break
					end
				end
			end
			RoomSpawning -= 1
		end)
	end
end
while RoomSpawning > 0 do
	wait()
end
print("Room Count: " .. tostring(#Rooms))
print("Finished setting room positions")
-- Bowyer-Watson triangulation algorithm
-- Create and push super tri
local SuperTri = Triangle.new(Vector2.new(-ARENA_SIZE * 2, -ARENA_SIZE), Vector2.new(ARENA_SIZE * 2, -ARENA_SIZE), Vector2.new(0, ARENA_SIZE * 3))
table.insert(Triangles, SuperTri)
local lapse = 0
for _, room in Rooms do
	local vertex = room.Position
	lapse += 1
	-- Mark triangles as bad if circumcircle contains vertex
	local badTris = {}
	do
		local i = 0
		local _shouldIncrement = false
		while true do
			if _shouldIncrement then
				i += 1
			else
				_shouldIncrement = true
			end
			if not (i < #Triangles) then
				break
			end
			local tri = Triangles[i + 1]
			if tri:InsideCircumcircle(vertex) then
				local _arg0 = { tri, i }
				table.insert(badTris, _arg0)
			end
		end
	end
	-- Find boundary of the polygonal hole
	local polygon = {}
	for _1, badTri in badTris do
		for _2, edge in badTri[1].Edges do
			local _arg0 = function(p)
				local _condition = p[2] ~= badTri[2]
				if _condition then
					local _edges = p[1].Edges
					local _arg0_1 = function(e)
						return edge:Equals(e)
					end
					-- ▼ ReadonlyArray.some ▼
					local _result = false
					for _k, _v in _edges do
						if _arg0_1(_v, _k - 1, _edges) then
							_result = true
							break
						end
					end
					-- ▲ ReadonlyArray.some ▲
					_condition = _result
				end
				return _condition
			end
			-- ▼ ReadonlyArray.some ▼
			local _result = false
			for _k, _v in badTris do
				if _arg0(_v, _k - 1, badTris) then
					_result = true
					break
				end
			end
			-- ▲ ReadonlyArray.some ▲
			if _result then
				continue
			end
			table.insert(polygon, edge)
		end
	end
	-- Remove bad tris from dataset
	do
		local i = #badTris - 1
		local _shouldIncrement = false
		while true do
			if _shouldIncrement then
				i -= 1
			else
				_shouldIncrement = true
			end
			if not (i >= 0) then
				break
			end
			local badTri = badTris[i + 1]
			local _arg0 = badTri[2]
			table.remove(Triangles, _arg0 + 1)
		end
	end
	RebuildBeams(polygon)
	wait(0.5)
	-- Create new tris from boundary and new vertex
	for _1, edge in polygon do
		local newTri = Triangle.new(vertex, edge.A, edge.B)
		table.insert(Triangles, newTri)
	end
	RebuildBeams()
	wait(0.5)
end
-- Remove remnant vertexes from original super-triangle
do
	local i = #Triangles - 1
	local _shouldIncrement = false
	while true do
		if _shouldIncrement then
			i -= 1
		else
			_shouldIncrement = true
		end
		if not (i >= 0) then
			break
		end
		local tri = Triangles[i + 1]
		do
			local i2 = 0
			local _shouldIncrement_1 = false
			while true do
				if _shouldIncrement_1 then
					i2 += 1
				else
					_shouldIncrement_1 = true
				end
				if not (i2 < #tri.Vertexes) then
					break
				end
				local vertex = tri.Vertexes[i2 + 1]
				if table.find(SuperTri.Vertexes, vertex) ~= nil then
					local _i = i
					table.remove(Triangles, _i + 1)
					break
				end
			end
		end
	end
end
RebuildBeams()
print("Tri Count: " .. tostring(#Triangles))
print("Finished the Bowyer-Watson triangulation algorithm")
wait(1)
-- Prim Minimum Spanning Tree
local Path = {}
local Edges = {}
local OpenVertexes = {}
local ClosedVertexes = {}
-- Collect edges & vertexes
for _, tri in Triangles do
	for _1, edge in tri.Edges do
		local _a = edge.A
		if not (table.find(OpenVertexes, _a) ~= nil) then
			local _a_1 = edge.A
			table.insert(OpenVertexes, _a_1)
		end
		local _b = edge.B
		if not (table.find(OpenVertexes, _b) ~= nil) then
			local _b_1 = edge.B
			table.insert(OpenVertexes, _b_1)
		end
		local _arg0 = function(e)
			return e:Equals(edge)
		end
		-- ▼ ReadonlyArray.some ▼
		local _result = false
		for _k, _v in Edges do
			if _arg0(_v, _k - 1, Edges) then
				_result = true
				break
			end
		end
		-- ▲ ReadonlyArray.some ▲
		if not _result then
			table.insert(Edges, edge)
		end
	end
end
local _position = Rooms[1].Position
table.insert(ClosedVertexes, _position)
-- Work way through to all pathable vertexes
while #OpenVertexes > 0 do
	local chosenEdge = nil
	local minWeight = math.huge
	for _, edge in Edges do
		-- Select edge only if edge is connected by exclusively one point
		local closed = 0
		local _a = edge.A
		if not (table.find(ClosedVertexes, _a) ~= nil) then
			closed += 1
		end
		local _b = edge.B
		if not (table.find(ClosedVertexes, _b) ~= nil) then
			closed += 1
		end
		if closed ~= 1 then
			continue
		end
		-- Weight selection based on the length of each edge
		if edge.Distance < minWeight then
			chosenEdge = edge
			minWeight = edge.Distance
		end
	end
	if chosenEdge == nil then
		break
	end
	-- Move proposed edge to the path
	local _chosenEdge = chosenEdge
	table.insert(Path, _chosenEdge)
	local _a = chosenEdge.A
	local _arg0 = (table.find(OpenVertexes, _a) or 0) - 1
	table.remove(OpenVertexes, _arg0 + 1)
	local _b = chosenEdge.B
	local _arg0_1 = (table.find(OpenVertexes, _b) or 0) - 1
	table.remove(OpenVertexes, _arg0_1 + 1)
	local _a_1 = chosenEdge.A
	table.insert(ClosedVertexes, _a_1)
	local _b_1 = chosenEdge.B
	table.insert(ClosedVertexes, _b_1)
end
RebuildBeams(Path)
print("Path Count: " .. tostring(#Path))
print("Finished the Prim's MST algorithm")
wait(1)
-- Randomly add extra edges
local chance = 0.2
for _, edge in Edges do
	local _arg0 = function(e)
		return e:Equals(edge)
	end
	-- ▼ ReadonlyArray.some ▼
	local _result = false
	for _k, _v in Path do
		if _arg0(_v, _k - 1, Path) then
			_result = true
			break
		end
	end
	-- ▲ ReadonlyArray.some ▲
	if _result then
		continue
	end
	local possibility = math.random()
	if possibility < chance then
		chance /= 2
		table.insert(Path, edge)
	end
end
RebuildBeams(Path)
print("Path Count: " .. tostring(#Path))
print("Finished randomly adding extra paths")
wait(1)
-- Room placement
local folder = Instance.new("Folder")
folder.Parent = game.Workspace
local function PlacePart(Pos, Size)
	local part = Instance.new("Part")
	part.Anchored = true
	part.Parent = folder
	part.Size = Vector3.new(Size.X, 1, Size.Y)
	part.Position = Vector3.new(Pos.X, 1.5, Pos.Y)
	return part
end
for _, room in Rooms do
	PlacePart(room.Position, room.Size)
end
print("Finished placing room parts")
wait(1)
-- Determine Door Positions
local DoorConnections = {}
-- Gets direction and locks it to 90 degree intervals
local function GetRoundedDirectionBetweenVectors(A, B)
	local _a = A
	local _b = B
	local C = _a - _b
	local theta = math.deg(math.atan2(C.Y, C.X))
	local dir = math.rad(math.round(theta / 90) * 90)
	return Vector2.new(math.cos(dir), math.sin(dir))
end
-- Positions door based on bounding box size and position
local function GetDoorOffsetPosition(b, v)
	local _position_1 = b.Position
	local _exp = b.Size / 2
	local _v = v
	local _arg0 = v * 0.5
	return _position_1 + (_exp * _v) + _arg0
end
-- Gets room & positions door
local function SetupDoorPosition(v, dir)
	local _arg0 = function(p)
		return p.Position == v
	end
	-- ▼ ReadonlyArray.find ▼
	local _result
	for _i, _v in Rooms do
		if _arg0(_v, _i - 1, Rooms) == true then
			_result = _v
			break
		end
	end
	-- ▲ ReadonlyArray.find ▲
	local room = _result
	local _arg0_1 = room ~= nil
	assert(_arg0_1)
	return GetDoorOffsetPosition(room, dir)
end
-- Positions door and adds it as a connection
for _, edge in Path do
	local A = SetupDoorPosition(edge.A, GetRoundedDirectionBetweenVectors(edge.B, edge.A))
	local B = SetupDoorPosition(edge.B, GetRoundedDirectionBetweenVectors(edge.A, edge.B))
	local _edge = Edge.new(A, B)
	table.insert(DoorConnections, _edge)
end
-- Create visuals for door placement (temporary)
for _, connection in DoorConnections do
	local A = PlacePart(connection.A, Vector2.one)
	A.Color = Color3.new(0.5, 0.1, 0.1)
	local _position_1 = A.Position
	local _yAxis = Vector3.yAxis
	A.Position = _position_1 + _yAxis
	local B = PlacePart(connection.B, Vector2.one)
	B.Color = A.Color
	local _position_2 = B.Position
	local _yAxis_1 = Vector3.yAxis
	B.Position = _position_2 + _yAxis_1
end
print("Finished placing door positions")
wait(1)
-- A* Algorithm
-- Setup room path costs
local Costs = {}
for _, room in Rooms do
	do
		local x = room.Min.X
		local _shouldIncrement = false
		while true do
			if _shouldIncrement then
				x += 1
			else
				_shouldIncrement = true
			end
			if not (x <= room.Max.X) then
				break
			end
			do
				local y = room.Min.Y
				local _shouldIncrement_1 = false
				while true do
					if _shouldIncrement_1 then
						y += 1
					else
						_shouldIncrement_1 = true
					end
					if not (y <= room.Max.Y) then
						break
					end
					local _arg0 = Vector2String(Vector2.new(x, y))
					Costs[_arg0] = 10
				end
			end
		end
	end
end
-- Gets the cost of the next spot on any given grid
local function GetCost(connection, a, b)
	local _position_1 = b.Position
	local _b = connection.B
	local cost = (_position_1 - _b).Magnitude
	local _arg0 = Vector2String(b.Position)
	local added = Costs[_arg0]
	cost += if added ~= nil then added else 5
	-- Added costs for turns
	local prior = a.Previous
	if prior ~= nil then
		if prior.X ~= b.Position.X and prior.Y ~= b.Position.Y then
			cost += 5
		end
	end
	return cost
end
-- Builds path from optimal costs
local function ReconstructPath(closed, node)
	local result = {}
	local currentNode = node
	-- Checks prior nodes and adds them to the results
	while currentNode.Previous ~= nil do
		local _position_1 = currentNode.Position
		table.insert(result, _position_1)
		local _arg0 = Vector2String(currentNode.Position)
		Costs[_arg0] = 1
		local _closed = closed
		local _arg0_1 = Vector2String(currentNode.Previous)
		local checkNode = _closed[_arg0_1]
		local _arg0_2 = checkNode ~= nil
		assert(_arg0_2)
		currentNode = checkNode
	end
	-- Ensures the last node is added
	local _position_1 = currentNode.Position
	table.insert(result, _position_1)
	local _arg0 = Vector2String(currentNode.Position)
	Costs[_arg0] = 1
	return result
end
-- Adjacent directions (it's simpler this way I promise)
local Adjacent = { Vector2.new(1, 0), Vector2.new(-1, 0), Vector2.new(0, 1), Vector2.new(0, -1) }
local function FindPath(connection)
	-- Bound path searching to area
	local Bounds = GetBoundingBoxFromMinMax(connection.A, connection.B)
	-- OpenSet keeps track of nodes ready for checking and ClosedSet ensures nodes aren't checked twice
	local OpenSet = {}
	local ClosedSet = {}
	-- For cost tracking
	local Grid = {}
	local startNode = Node.new(connection.A, 0)
	local _arg0 = Vector2String(connection.A)
	Grid[_arg0] = startNode
	table.insert(OpenSet, startNode)
	-- Begin running through OpenSet
	while #OpenSet > 0 do
		local node = table.remove(OpenSet, 1)
		node.Position = RoundVector2(node.Position)
		local _arg0_1 = Vector2String(node.Position)
		ClosedSet[_arg0_1] = node
		-- If node has reached the end: end the function and return the path
		if node.Position == RoundVector2(connection.B) then
			return ReconstructPath(ClosedSet, node)
		end
		for _, offset in Adjacent do
			local offsetPos = RoundVector2(node.Position + offset)
			-- Ensure offset is inside bounds and has not been checked already
			local _condition = not Bounds:Inside(offsetPos)
			if not _condition then
				local _arg0_2 = Vector2String(offsetPos)
				_condition = ClosedSet[_arg0_2] ~= nil
			end
			if _condition then
				continue
			end
			local _arg0_2 = Vector2String(offsetPos)
			local pN = Grid[_arg0_2]
			local neighbor = if pN ~= nil then pN else Node.new(offsetPos, math.huge)
			local newCost = node.Cost + GetCost(connection, node, neighbor)
			-- Always override node if node cost is lesser than prior path checks
			if newCost < neighbor.Cost then
				neighbor.Cost = newCost
				neighbor.Previous = node.Position
				local _arg0_3 = Vector2String(offsetPos)
				Grid[_arg0_3] = neighbor
				table.insert(OpenSet, neighbor)
			end
		end
		-- Ensure the most cost efficient path is being calculated first
		local _arg0_2 = function(a, b)
			return a.Cost < b.Cost
		end
		table.sort(OpenSet, _arg0_2)
		wait()
	end
	-- By default return no path if path is not found
	return nil
end
for _, connection in DoorConnections do
	local path = FindPath(connection)
	if path ~= nil then
		for _1, p in path do
			local part = PlacePart(p, Vector2.one)
			part.Color = Color3.new(0.1, 0.1, 0.7)
		end
		print("Placed path: " .. tostring(connection.A) .. " to " .. tostring(connection.B))
	end
end
print("Finished the A* pathing algorithm")
