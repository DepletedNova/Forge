export class Node {
	Cost: number;
	Position: Vector2;
	Previous?: Vector2;

	constructor(Position: Vector2, Cost: number, Previous?: Vector2) {
		this.Position = Position;
		this.Cost = Cost;
		this.Previous = Previous;
	}
}