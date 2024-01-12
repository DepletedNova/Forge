import { Find, WaitFor } from "shared/PathUtility";

const Players = game.GetService("Players");
const RunService = game.GetService("RunService");
const ReplicatedStorage = game.GetService("ReplicatedStorage");
const Packets = ReplicatedStorage.WaitForChild("Packets");

// API
export function GetEvent(Name: string): BindableEvent {
	let Events: Folder | undefined;
	if (RunService.IsClient()) {
		const player = Players.LocalPlayer;
		const playerScripts = WaitFor(player, "PlayerScripts", "PlayerScripts");
		assert(playerScripts !== undefined);
		Events = WaitFor(playerScripts, "Folder", "Events");
	} else {
		const ServerStorage = game.GetService("ServerStorage");
		Events = WaitFor(ServerStorage, "Folder", "Events");
	}
	assert(Events !== undefined);
	return Find(Events, "BindableEvent", Name, false) as BindableEvent;
}

// Client
if (RunService.IsClient()) {
	// Player
	const player = Players.LocalPlayer;
	player.CharacterAdded.Connect((char) => {
		GetEvent("Spawn").Fire(player, char);

		const humanoid = WaitFor(char, "Humanoid", "Humanoid");
		assert(humanoid !== undefined);
		const deathConnection = humanoid.Died.Connect(() => {
			deathConnection.Disconnect();
			GetEvent("Death").Fire(player, char);
		});
	});
}

// Server
if (RunService.IsServer()) {
	const playerConnections: [Player, RBXScriptConnection][] = [];

	// Players
	Players.PlayerAdded.Connect((player) => {
		GetEvent("PlayerJoin").Fire(player);

		const charConnection = player.CharacterAdded.Connect((char) => {
			GetEvent("CharacterSpawn").Fire(player, char);

			const humanoid = WaitFor(char, "Humanoid", "Humanoid");
			assert(humanoid !== undefined);
			const deathConnection = humanoid.Died.Connect(() => {
				deathConnection.Disconnect();

				GetEvent("CharacterDeath").Fire(player, char);
			});
		});

		playerConnections.push([player, charConnection]);
	});

	Players.PlayerRemoving.Connect((player) => {
		GetEvent("PlayerLeave").Fire(player);

		for (let i = 0; i < 0; i++) {
			const connections = playerConnections[i];
			if (connections[0] !== player) continue;

			connections[1].Disconnect();
			playerConnections.remove(i);
			break;
		}
	});
}
