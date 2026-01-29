pragma Singleton
import QtQuick
import Qt.labs.settings 1.1
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell

Item {
    id: taskbarManager

    // Сырые окна (каждое окно — отдельный элемент)
    property var clients: []

    // Закрепленные (порядок важен)
    // [{ className: "firefox", title: "Firefox" }, ...]
    property var pinned: []

    // Модель для дока
    // [{ className, title, running, address, workspace, count, pinned }, ...]
    property var items: []

    Settings {
        id: store
        category: "taskbar"
        // файл где хранить (у тебя уже работает — оставляю)
        fileName: Quickshell.env("HOME") + "/.config/quickshell/taskbar.ini"

        // ВАЖНО: храним JSON строкой (это 100% поддерживается)
        property string pinnedJson: "[]"
    }

    function normalizeClients(data) {
        if (!Array.isArray(data)) return [];

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
        }).filter(c => c.title !== "" && c.address !== "" && c.className !== "");
    }

    function normAddress(addr) {
        const s = String(addr ?? "").trim();
        if (s === "") return "";
        return s.startsWith("0x") ? s : ("0x" + s);
    }

    function loadPinned() {
        try {
            const parsed = JSON.parse(store.pinnedJson || "[]");
            pinned = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            pinned = [];
        }
        rebuildItems();
    }

    function savePinned() {
        try {
            store.pinnedJson = JSON.stringify(pinned);
            store.sync(); // принудительно записать на диск
        } catch (e) {
            // ignore
        }
    }

    function isPinned(className) {
        if (!className) return false;
        for (let i = 0; i < pinned.length; i++) {
            if (pinned[i].className === className) return true;
        }
        return false;
    }

    function togglePinned(className, title) {
        if (!className) return;

        let found = false;
        const next = [];

        for (let i = 0; i < pinned.length; i++) {
            const p = pinned[i];
            if (p.className === className) {
                found = true; // удаляем
            } else {
                next.push(p);
            }
        }

        if (!found) {
            next.push({ className: className, title: title ?? className });
        }

        pinned = next;
        savePinned();
        rebuildItems();
    }

    function rebuildItems() {
        const byClass = Object.create(null);

        for (let i = 0; i < clients.length; i++) {
            const c = clients[i];
            if (!c.className) continue;

            let entry = byClass[c.className];
            if (!entry) {
                entry = {
                    className: c.className,
                    title: c.title,
                    running: true,
                    address: c.address,
                    workspace: c.workspace,
                    count: 1
                };
                byClass[c.className] = entry;
            } else {
                entry.count += 1;
            }
        }

        const result = [];

        // 1) Закрепленные
        for (let i = 0; i < pinned.length; i++) {
            const p = pinned[i];
            const live = byClass[p.className];

            if (live) {
                result.push({
                    className: live.className,
                    title: live.title || p.title || live.className,
                    running: true,
                    address: live.address,
                    workspace: live.workspace,
                    count: live.count,
                    pinned: true
                });
                delete byClass[p.className];
            } else {
                result.push({
                    className: p.className,
                    title: p.title || p.className,
                    running: false,
                    address: "",
                    workspace: "",
                    count: 0,
                    pinned: true
                });
            }
        }

        // 2) Остальные запущенные
        for (const key in byClass) {
            const live2 = byClass[key];
            result.push({
                className: live2.className,
                title: live2.title || live2.className,
                running: true,
                address: live2.address,
                workspace: live2.workspace,
                count: live2.count,
                pinned: false
            });
        }

        items = result;
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

            clients = clients.filter(c => c.address !== client.address).concat([client]);
            rebuildItems();
            return;
        }

        if (event.name === "closewindow") {
            const address = normAddress(event.data);
            if (!address) return;

            clients = clients.filter(c => c.address !== address);
            rebuildItems();
            return;
        }

        if (event.name === "windowtitlev2") {
            const parts = String(event.data ?? "").split(",");
            const address = normAddress(parts[0]);
            const title = parts.slice(1).join(",").trim();

            clients = clients.map(item => {
                if (item.address === address) {
                    return Object.assign({}, item, { title: title });
                }
                return item;
            });

            rebuildItems();
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
                    clients = [];
                    rebuildItems();
                    return;
                }
                try {
                    const parsed = JSON.parse(output);
                    clients = normalizeClients(parsed);
                    rebuildItems();
                } catch (error) {
                    clients = [];
                    rebuildItems();
                }
            }
        }
    }

    Component.onCompleted: {
        loadPinned();                 // сначала прочитать закрепления
        clientsProcess.running = true; // потом загрузить окна
        Hyprland.rawEvent.connect(handleRawEvent);
    }
}

