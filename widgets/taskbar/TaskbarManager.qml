pragma Singleton
import Quickshell.Io
import QtQuick
import Quickshell.Hyprland

Item {
	id: taskbarManager
	property var clients: []

	function normalizeClients(data) {
		if (!Array.isArray(data)) {
			return [];
		}
		return data.map(client => {
			const title = client.title ? String(client.title).trim() : "";
			const className = client.class ? String(client.class).trim() : "";
			const ws = client.workspace
            ? (client.workspace.name ?? client.workspace.id ?? "")
			: (client.workspace ?? "");

			return {
				address: client.address ?? "",
				title: title !== "" ? title : className,
				className: className,
				workspace: ws
			};
		}).filter(client => client.title !== "");
	}

	function handleRawEvent(event) {
		if (event.name === "openwindow") {
			const parts = event.data.split(',');
			const address = (parts[0] ?? "").trim();
			const workspace = (parts[1] ?? "").trim();
			const className = (parts[2] ?? "").trim();
			const title = parts.slice(3).join(',').trim();

			const normalized = normalizeClients([{
				title: title,
				class: className,
				address: address,
				workspace: workspace
			}]);

			const client = normalized[0];
			if (client) {
				taskbarManager.clients = [
					...taskbarManager.clients.filter(c => c.address !== client.address),
					client
				];
			}
			return;
		}

		if (event.name === "closewindow") {
			const address = String(event.data ?? "").trim();
			if (address.length === 0) return;

			taskbarManager.clients = taskbarManager.clients.filter(c => c.address !== address);
			return;
		}
	}
	Process {
		id: clientsProcess
		command: ["hyprctl", "clients", "-j"]
		running: false
		stdout: StdioCollector {
			onStreamFinished: {
				const output = this.text.trim();
				if (output.length === 0) {
					taskbarManager.clients = [];
					return;
				}
				try {
					const parsed = JSON.parse(output);
					taskbarManager.clients = normalizeClients(parsed);
				} catch (error) {
					taskbarManager.clients = [];
				}
			}
		}
	}

	Component.onCompleted: {
		clientsProcess.running = true;
		Hyprland.rawEvent.connect(handleRawEvent);
	}
}
