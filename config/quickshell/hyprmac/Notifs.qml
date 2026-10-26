pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Server notifikasi hyprmac (popup + riwayat untuk Notification Center)
Singleton {
    id: root

    property bool centerOpen: false
    property bool dnd: false
    property list<Notification> popups: []
    property var arrivedAt: ({}) // id -> waktu tiba (ms)

    readonly property list<Notification> list: server.trackedNotifications.values

    function removePopup(n: Notification): void {
        popups = popups.filter(p => p !== n);
    }

    function clearAll(): void {
        for (const n of [...list])
            n.dismiss();
        popups = [];
    }

    function activate(n: Notification): void {
        const action = n.actions.find(a => a.identifier === "default");
        if (action)
            action.invoke();
        else
            n.dismiss();
        removePopup(n);
    }

    function ago(n: Notification): string {
        const ms = Date.now() - (arrivedAt[n.id] ?? Date.now());
        const min = Math.floor(ms / 60000);
        if (min < 1)
            return "sekarang";
        if (min < 60)
            return `${min} mnt lalu`;
        return `${Math.floor(min / 60)} jam lalu`;
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            root.arrivedAt[n.id] = Date.now();
            if (!root.dnd && !root.centerOpen)
                root.popups = [n, ...root.popups.filter(p => p !== n)].slice(0, 4);
            n.closed.connect(() => root.removePopup(n));
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            const open = !root.centerOpen;
            Globals.closePopups();
            root.centerOpen = open;
        }

        function toggleDnd(): void {
            root.dnd = !root.dnd;
        }

        function clear(): void {
            root.clearAll();
        }
    }
}
