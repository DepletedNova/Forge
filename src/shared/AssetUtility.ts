import { Find, WaitFor } from "./PathUtility";

const ReplicatedStorage = game.GetService("ReplicatedStorage");
const Directory = WaitFor(ReplicatedStorage, "Folder", "Assets") as Folder;

export function GetAsset(subsection: string, name: string): Model {
	const subFolder = WaitFor(Directory, "Folder", subsection) as Folder;
	const item = Find(subFolder, "Model", name);
	assert(item !== undefined);
	return item;
}