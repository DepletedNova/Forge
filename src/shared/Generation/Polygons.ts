function StandardLinear(_1: Vector2, _2: Vector2) {
	const a = _2.Y - _1.Y;
	const b = -(_2.X - _1.X);
	const c = a * _1.X + b * _2.Y;
	return [a, b, c];
}

function PerpendicularLineAt(P: Vector2, Q: number[]) {
	const a = -Q[1]
	const b = Q[0];
	const c = a * P.X + b * P.Y;
	return [a, b, c];
}

function GetCrossingPoint(pAB: number[], pBC: number[]) {
	const A1 = pAB[0];
	const A2 = pBC[0];
	const B1 = pAB[1];
	const B2 = pBC[1];
	const C1 = pAB[2];
	const C2 = pBC[2];

	const Determinant = A1 * B2 - A2 * B1;
	const DeterminantX = C1 * B2 - C2 * B1;
	const DeterminantY = A1 * C2 - A2 * C1;

	const x = DeterminantX / Determinant;
	const y = DeterminantY / Determinant;

	return new Vector2(x, y);
}

function GetCircumcenter(A: Vector2, B: Vector2, C: Vector2) {
	const AB = StandardLinear(A, B);
	const BC = StandardLinear(B, C);

	const mAB = A.Lerp(B, 0.5);
	const mBC = B.Lerp(C, 0.5);

	const pAB = PerpendicularLineAt(mAB, AB);
	const pBC = PerpendicularLineAt(mBC, BC);

	const circumcirle = GetCrossingPoint(pAB, pBC);

	return circumcirle;
}

export class Edge {
	readonly A: Vector2;
	readonly B: Vector2;
	readonly Distance: number;

	constructor(A: Vector2, B: Vector2) {
		this.A = A;
		this.B = B;

		this.Distance = math.floor(A.sub(B).Magnitude);
	}

	Contains(compare: Vector2): boolean {
		return compare === this.A || compare === this.B;
	}

	Equals(compare: Edge): boolean {
		return (compare.A === this.A && compare.B === this.B) || (compare.A === this.B && compare.B === this.A);
	}
}

export class Triangle {
	readonly Vertexes: Vector2[] = [];
	readonly Edges: Edge[] = [];

	readonly Circumradius: number;
	readonly Circumcenter: Vector2;
	
	constructor(p1: Vector2, p2: Vector2, p3: Vector2) {
		this.Vertexes.push(p1, p2, p3);

		this.Edges.push(
			new Edge(p1, p2),
			new Edge(p2, p3),
			new Edge(p3, p1),
		)

		this.Circumcenter = GetCircumcenter(p1, p2, p3);
		this.Circumradius = math.abs(this.Circumcenter.sub(p1).Magnitude);
	}

	InsideCircumcircle(point: Vector2): boolean {
		return math.abs(point.sub(this.Circumcenter).Magnitude) <= this.Circumradius;
	}
}