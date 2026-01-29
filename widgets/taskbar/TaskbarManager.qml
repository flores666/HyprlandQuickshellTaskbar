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
		}).filter(client => client.title !== "" && client.address !== "");
	}

	function normAddress(addr) {
		const s = String(addr ?? "").trim();
		if (s === "") return "";
		return s.startsWith("0x") ? s : ("0x" + s);
	}

	function handleRawEvent(event) {
		if (event.name === "openwindow") {
			const parts = String(event.data ?? "").split(",");

			const address = normAddress(parts[0]);
			const workspace = (parts[1] ?? "").trim();
			const className = (parts[2] ?? "").trim();
			const title = parts.slice(3).join(",").trim();

			const normalized = normalizeClients([{
				title: title,
				class: className,
				address: address,
				workspace: workspace
			}]);

			const client = normalized[0];
			if (!client) return;

			taskbarManager.clients = [
				...taskbarManager.clients.filter(c => c.address !== client.address),
				client
			];
			return;
		}

		if (event.name === "closewindow") {
			const address = normAddress(event.data);
			if (!address) return;

			taskbarManager.clients = taskbarManager.clients.filter(c => c.address !== address);
			return;
		}

		if (event.name === "windowtitlev2") {
			const parts = String(event.data ?? "").split(",");
			const address = normAddress(parts[0]);
			const title = parts.slice(1).join(",").trim();

			taskbarManager.clients = taskbarManager.clients.map(item => {
				if (item.address === address) {
					return Object.assign({}, item, { title: title });
				}
				return item;
			});
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
