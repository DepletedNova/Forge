export function RoundVector2(a: Vector2): Vector2 {
	return new Vector2(math.round(a.X), math.round(a.Y));
}

export function Vector2String(a: Vector2): string {
	return tostring(math.round(a.X) + ", " + math.round(a.Y));
}