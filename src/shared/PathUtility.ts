export function Find<T extends keyof Instances>(
	Obj: Instance,
	ClassName: T,
	Name: string,
	Recursive: boolean = false,
): Instances[T] | undefined {
	return (Obj.FindFirstChild(Name, Recursive) as Instances[T]) || undefined;
}

export function FindWhichIsA<T extends keyof Instances>(
	Obj: Instance,
	ClassName: T,
	Recursive: boolean = false,
): Instances[T] | undefined {
	return (Obj.FindFirstChildWhichIsA(ClassName, Recursive) as Instances[T]) || undefined;
}

export function WaitFor<T extends keyof Instances>(
	Obj: Instance,
	ClassName: T,
	Name: string,
): Instances[T] | undefined {
	return (Obj.WaitForChild(Name, 5) as Instances[T]) || undefined;
}
