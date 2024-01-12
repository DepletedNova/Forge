export class BoundingBox {
	Position: Vector2;
	Size: Vector2;

	readonly Min: Vector2;
	readonly Max: Vector2;

	constructor(Position: Vector2, Size: Vector2) {
		this.Position = Position;
		this.Size = Size;

		this.Min = new Vector2(this.Position.X - this.Size.X / 2, this.Position.Y - this.Size.Y / 2);
		this.Max = new Vector2(this.Position.X + this.Size.X / 2, this.Position.Y + this.Size.Y / 2);
	}

	Overlaps(o: BoundingBox, expand: number = 0): boolean {
		const min1 = this.Min;
		const max1 = this.Max;
		const min2 = o.Min;
		const max2 = o.Max;

		const halved = expand * 0.5;

		return (max1.X + halved >= min2.X - halved && max2.X + halved >= min1.X - halved) && 
			(max1.Y + halved >= min2.Y - halved && max2.Y + halved >= min1.Y - halved);
	}

	Inside(o: Vector2): boolean {
		return this.Min.X <= o.X && this.Max.X >= o.X &&
			this.Min.Y <= o.Y && this.Max.Y >= o.Y;
	}
}

export function GetBoundingBoxFromMinMax(A: Vector2, B: Vector2) {
	return new BoundingBox(
		new Vector2((A.X - B.X) / 2 + B.X, (A.Y - B.Y) / 2 + B.Y),
		new Vector2(math.abs(A.X - B.X), math.abs(A.Y - B.Y))
	);
}