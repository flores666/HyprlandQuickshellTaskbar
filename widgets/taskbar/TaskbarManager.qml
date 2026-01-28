pragma Singleton
import Quickshell.Io
import QtQuick

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
			return {
				address: client.address ?? "",
				title: title !== "" ? title : className,
				className: className
			};
		}).filter(client => client.title !== "");
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

	Timer {
		interval: 1000
		running: true
		repeat: true
		onTriggered: clientsProcess.running = true
	}
}
