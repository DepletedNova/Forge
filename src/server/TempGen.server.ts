import { Find } from "shared/PathUtility";
import { BoundingBox, GetBoundingBoxFromMinMax } from "shared/Generation/BoundingBox";
import { Edge, Triangle } from "shared/Generation/Polygons";
import { Node } from "shared/Generation/Node";
import { RoundVector2, Vector2String } from "shared/Vector2Util";

const ROOM_COUNT = 5;
const MAX_TRIES = 10;
const MINIMUM_SPACING = 3;
const ARENA_SIZE = 50;

const SPAWN = new BoundingBox(Vector2.zero, new Vector2(5, 5));
const ROOM_SIZE = new Vector2(5, 5);

const SHOW_CIRCUMCIRCLES = true;

// temp visuals
const BeamPart = new Instance("Part");
BeamPart.Anchored = true;
BeamPart.Parent = game.Workspace;
BeamPart.Size = Vector3.one;
BeamPart.Transparency = 1;
BeamPart.Position = Vector3.zero;

let lastAttachment: Attachment | undefined;
function BuildBeam(Pos: Vector2, detected: boolean = false) {
	const attachment = new Instance("Attachment");
	attachment.Parent = BeamPart;
	attachment.CFrame = new CFrame(new Vector3(Pos.X, detected ? 0.5 : 0, Pos.Y));

	if (lastAttachment !== undefined) {
		const beam = new Instance("Beam");
		beam.Attachment0 = lastAttachment;
		beam.Attachment1 = attachment;
		beam.Parent = BeamPart;
		beam.FaceCamera = true;

		if (detected) {
			beam.Color = new ColorSequence(new Color3(1, 0, 0));
		}
	}

	lastAttachment = attachment;
}

const Triangles: Triangle[] = [];

function RebuildBeams(polygons: Edge[] = [], clear: boolean = true) {
	if (clear) {
		BeamPart.ClearAllChildren();
	}
	for (const tri of Triangles) {
		lastAttachment = undefined;
		for (const vertex of tri.Vertexes) {
			BuildBeam(vertex);
		}
		BuildBeam(tri.Vertexes[0]);

		if (SHOW_CIRCUMCIRCLES) {
			const circle = new Instance("Part");
			circle.Anchored = true;
			circle.Parent = BeamPart;
			circle.Size = Vector3.one;
			circle.Transparency = 0.95;
			circle.Position = new Vector3(tri.Circumcenter.X, 0, tri.Circumcenter.Y);
			circle.Rotation = new Vector3(0, 0, 90);

			const mesh = new Instance("SpecialMesh");
			mesh.Parent = circle;
			mesh.MeshType = Enum.MeshType.Cylinder;
			mesh.Scale = new Vector3(0.5, tri.Circumradius * 2, tri.Circumradius * 2);
		}
	}

	for (const poly of polygons) {
		lastAttachment = undefined;
		BuildBeam(poly.A, clear);
		BuildBeam(poly.B, clear);
	}
}

// Random room placement
const Rooms: BoundingBox[] = [SPAWN];

let RoomSpawning = ROOM_COUNT;
for (let i = 0; i < ROOM_COUNT; i++) {
	// Multi-threaded room placement
	spawn(() => {
		// Limit number of tries
		for (let currentTry = 0; currentTry < MAX_TRIES; currentTry++) {
			// Grab a random position to place a room
			const box = new BoundingBox(new Vector2(math.random(ARENA_SIZE) - ARENA_SIZE / 2, math.random(ARENA_SIZE) - ARENA_SIZE / 2), ROOM_SIZE);

			// Check if rooms overlap with any other or spawn room
			let result = false;
			for (const room of Rooms) {
				result ||= room.Overlaps(box, MINIMUM_SPACING);
			}

			//result ||= SPAWN.Overlaps(box, MINIMUM_SPACING);
			
			// if rooms do not overlap skip other tries and place the room
			if (!result) {
				Rooms.push(box);
				break;
			}
		}

		RoomSpawning--; // Allow room to be removed from queue regardless of try count
	});
}

while (RoomSpawning > 0) wait();

print("Room Count: " + Rooms.size());
print("Finished setting room positions");

// Bowyer-Watson triangulation algorithm

// Create and push super tri
const SuperTri = new Triangle(
	new Vector2(-ARENA_SIZE * 2, -ARENA_SIZE),
	new Vector2(ARENA_SIZE * 2, -ARENA_SIZE),
	new Vector2(0, ARENA_SIZE * 3),
);
Triangles.push(SuperTri);

let lapse = 0;
for (const room of Rooms) {
	const vertex = room.Position;

	lapse++;

	// Mark triangles as bad if circumcircle contains vertex
	const badTris: [Triangle, number][] = [];
	for (let i = 0; i < Triangles.size(); i++) {
		const tri = Triangles[i];

		if (tri.InsideCircumcircle(vertex)) {
			badTris.push([tri, i]);
		}
	}

	// Find boundary of the polygonal hole
	const polygon: Edge[] = [];
	for (const badTri of badTris) {
		for (const edge of badTri[0].Edges) {
			if (badTris.some(p => p[1] !== badTri[1] && 
				p[0].Edges.some(e => edge.Equals(e)))) 
				continue;
			
			polygon.push(edge);
		}
	}

	// Remove bad tris from dataset
	for (let i = badTris.size() - 1; i >= 0; i--) {
		const badTri = badTris[i];
		Triangles.remove(badTri[1]);
	}

	RebuildBeams(polygon);

	wait(0.5);

	// Create new tris from boundary and new vertex
	for (const edge of polygon) {
		const newTri = new Triangle(vertex, edge.A, edge.B);
		Triangles.push(newTri);
	}

	RebuildBeams();

	wait(0.5);
}

// Remove remnant vertexes from original super-triangle
for (let i = Triangles.size() - 1; i >= 0; i--) {
	const tri = Triangles[i];
	for (let i2 = 0; i2 < tri.Vertexes.size(); i2++) {
		const vertex = tri.Vertexes[i2];
		if (SuperTri.Vertexes.includes(vertex)) {
			Triangles.remove(i);
			break;
		}
	}
}

RebuildBeams();

print("Tri Count: " + Triangles.size());
print("Finished the Bowyer-Watson triangulation algorithm")

wait(1);

// Prim Minimum Spanning Tree

const Path: Edge[] = [];

const Edges: Edge[] = [];

const OpenVertexes: Vector2[] = []; // 
const ClosedVertexes: Vector2[] = [];

// Collect edges & vertexes
for (const tri of Triangles) {
	for (const edge of tri.Edges) {
		if (!OpenVertexes.includes(edge.A)) OpenVertexes.push(edge.A);
		if (!OpenVertexes.includes(edge.B)) OpenVertexes.push(edge.B);
		if (!Edges.some(e => e.Equals(edge))) Edges.push(edge);
	}
}

ClosedVertexes.push(Rooms[0].Position);

// Work way through to all pathable vertexes
while (OpenVertexes.size() > 0) {
	let chosenEdge: Edge | undefined = undefined;
	let minWeight = math.huge;

	for (const edge of Edges) {
		// Select edge only if edge is connected by exclusively one point
		let closed = 0;
		if (!ClosedVertexes.includes(edge.A)) closed++;
		if (!ClosedVertexes.includes(edge.B)) closed++;
		if (closed !== 1) continue;

		// Weight selection based on the length of each edge
		if (edge.Distance < minWeight) {
			chosenEdge = edge;
			minWeight = edge.Distance;
		}
	}

	if (chosenEdge === undefined) break;
	
	// Move proposed edge to the path
	Path.push(chosenEdge);
	OpenVertexes.remove(OpenVertexes.indexOf(chosenEdge.A));
	OpenVertexes.remove(OpenVertexes.indexOf(chosenEdge.B));
	ClosedVertexes.push(chosenEdge.A);
	ClosedVertexes.push(chosenEdge.B);
}

RebuildBeams(Path);

print("Path Count: " + Path.size());
print("Finished the Prim's MST algorithm")

wait(1)

// Randomly add extra edges
let chance = 0.2;
for (const edge of Edges) {
	if (Path.some(e => e.Equals(edge))) continue;

	const possibility = math.random();
	if (possibility < chance) {
		chance /= 2;
		Path.push(edge);
	}
}

RebuildBeams(Path);

print("Path Count: " + Path.size());
print("Finished randomly adding extra paths");

wait(1);

// Room placement
const folder = new Instance("Folder");
folder.Parent = game.Workspace;
function PlacePart(Pos: Vector2, Size: Vector2): Part {
	const part = new Instance("Part");
	part.Anchored = true;
	part.Parent = folder;
	part.Size = new Vector3(Size.X, 1, Size.Y);
	part.Position = new Vector3(Pos.X, 1.5, Pos.Y);
	return part;
}

for (const room of Rooms) {
	PlacePart(room.Position, room.Size);
}

print("Finished placing room parts");

wait(1);

// Determine Door Positions
const DoorConnections: Edge[] = [];

// Gets direction and locks it to 90 degree intervals
function GetRoundedDirectionBetweenVectors(A: Vector2, B: Vector2): Vector2 {
	const C = A.sub(B);
	const theta = math.deg(math.atan2(C.Y, C.X));
	const dir = math.rad(math.round(theta / 90) * 90);
	return new Vector2(math.cos(dir), math.sin(dir));
}

// Positions door based on bounding box size and position
function GetDoorOffsetPosition(b: BoundingBox, v: Vector2): Vector2 {
	return b.Position.add(b.Size.div(2).mul(v)).add(v.mul(0.5));
}

// Gets room & positions door
function SetupDoorPosition(v: Vector2, dir: Vector2): Vector2 {
	const room = Rooms.find(p => p.Position === v);
	assert(room !== undefined);
	return GetDoorOffsetPosition(room, dir);
}

// Positions door and adds it as a connection
for (const edge of Path) {
	const A = SetupDoorPosition(edge.A, GetRoundedDirectionBetweenVectors(edge.B, edge.A));
	const B = SetupDoorPosition(edge.B, GetRoundedDirectionBetweenVectors(edge.A, edge.B));
	DoorConnections.push(new Edge(A, B));
}

// Create visuals for door placement (temporary)
for (const connection of DoorConnections) {
	const A = PlacePart(connection.A, Vector2.one);
	A.Color = new Color3(0.5, 0.1, 0.1);
	A.Position = A.Position.add(Vector3.yAxis);

	const B = PlacePart(connection.B, Vector2.one);
	B.Color = A.Color;
	B.Position = B.Position.add(Vector3.yAxis);
}

print("Finished placing door positions");

wait(1);

// A* Algorithm

// Setup room path costs
const Costs = new Map<string, number>();
for (const room of Rooms) {
	for (let x = room.Min.X; x <= room.Max.X; x++) {
		for (let y = room.Min.Y; y <= room.Max.Y; y++) {
			Costs.set(Vector2String(new Vector2(x, y)), 10);
		}
	}
}

// Gets the cost of the next spot on any given grid
function GetCost(connection: Edge, a: Node, b: Node): number {
	let cost = b.Position.sub(connection.B).Magnitude; // Cost based on distance
	const added = Costs.get(Vector2String(b.Position));
	cost += added !== undefined ? added : 5; // Cost based on rooms (10), empty (5), and halls (1)

	// Added costs for turns
	const prior = a.Previous;
	if (prior !== undefined) {
		if (prior.X !== b.Position.X && prior.Y !== b.Position.Y) {
			cost += 5;
		}
	}

	return cost;
}

// Builds path from optimal costs
function ReconstructPath(closed: Map<string, Node>, node: Node) {
	const result = new Array<Vector2>();
	let currentNode: Node = node;

	// Checks prior nodes and adds them to the results
	while (currentNode.Previous !== undefined) {
		result.push(currentNode.Position);
		Costs.set(Vector2String(currentNode.Position), 1);

		const checkNode = closed.get(Vector2String(currentNode.Previous));
		assert(checkNode !== undefined);

		currentNode = checkNode;
	}
	
	// Ensures the last node is added
	result.push(currentNode.Position);
	Costs.set(Vector2String(currentNode.Position), 1);

	return result;
}

// Adjacent directions (it's simpler this way I promise)
const Adjacent: Vector2[] = [
	new Vector2(1, 0),
	new Vector2(-1, 0),
	new Vector2(0, 1),
	new Vector2(0, -1),
];

function FindPath(connection: Edge) {
	// Bound path searching to area
	const Bounds = GetBoundingBoxFromMinMax(connection.A, connection.B);

	// OpenSet keeps track of nodes ready for checking and ClosedSet ensures nodes aren't checked twice
	const OpenSet: Node[] = [];
	const ClosedSet = new Map<string, Node>();

	// For cost tracking
	const Grid = new Map<string, Node>();

	const startNode = new Node(connection.A, 0);
	Grid.set(Vector2String(connection.A), startNode);
	OpenSet.push(startNode);

	// Begin running through OpenSet
	while (OpenSet.size() > 0) {
		const node = OpenSet.shift() as Node;
		node.Position = RoundVector2(node.Position);
		ClosedSet.set(Vector2String(node.Position), node);

		// If node has reached the end: end the function and return the path
		if (node.Position === RoundVector2(connection.B)) {
			return ReconstructPath(ClosedSet, node);
		}

		for (const offset of Adjacent) {
			const offsetPos = RoundVector2(node.Position.add(offset));
			// Ensure offset is inside bounds and has not been checked already
			if (!Bounds.Inside(offsetPos) || ClosedSet.has(Vector2String(offsetPos))) {
				continue;
			}

			const pN = Grid.get(Vector2String(offsetPos));
			const neighbor = pN !== undefined ? pN : new Node(offsetPos, math.huge);

			const newCost = node.Cost + GetCost(connection, node, neighbor);

			// Always override node if node cost is lesser than prior path checks
			if (newCost < neighbor.Cost) {
				neighbor.Cost = newCost;
				neighbor.Previous = node.Position;

				Grid.set(Vector2String(offsetPos), neighbor);
				
				OpenSet.push(neighbor);
			}
		}

		// Ensure the most cost efficient path is being calculated first
		OpenSet.sort((a, b) => a.Cost < b.Cost);
		
		wait();
	}

	// By default return no path if path is not found
	return undefined;
}

for (const connection of DoorConnections) {
	const path = FindPath(connection);
	if (path !== undefined) {
		for (const p of path) {
			const part = PlacePart(p, Vector2.one);
			part.Color = new Color3(0.1, 0.1, 0.7);
		}
		print("Placed path: " + tostring(connection.A) + " to " + tostring(connection.B))
	}
}

print("Finished the A* pathing algorithm");