pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool launchpadOpen: false
    property bool appleMenuOpen: false
    property bool controlCenterOpen: false
    property bool aboutOpen: false
    property bool screenshotOpen: false
    property bool missionOpen: false
    property string powerDialog: "" // "", "power", "shutdown", "restart", "logout"

    // Aplikasi yang disematkan di dock, satu id .desktop per baris (file: dock-pinned)
    property list<string> pinned: []

    // Hanya satu menu/panel melayang yang terbuka sekaligus
    function closePopups(): void {
        appleMenuOpen = false;
        controlCenterOpen = false;
        Notifs.centerOpen = false;
    }

    function hyprDispatch(lua: string): void {
        Quickshell.execDetached(["hyprctl", "dispatch", lua]);
    }

    function windowSelector(address: string): string {
        return "address:" + (address.startsWith("0x") ? address : "0x" + address);
    }

    // Aksi daya lewat skrip yang sudah ada (menutup aplikasi dengan rapi dulu)
    function power(action: string): void {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/power.sh", action]);
    }

    FileView {
        path: Quickshell.shellPath("dock-pinned")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.pinned = text().split("\n").map(l => l.trim()).filter(l => l && !l.startsWith("#"))
    }

    IpcHandler {
        target: "launchpad"

        function toggle(): void {
            root.launchpadOpen = !root.launchpadOpen;
        }

        function open(): void {
            root.launchpadOpen = true;
        }

        function close(): void {
            root.launchpadOpen = false;
        }
    }

    IpcHandler {
        target: "applemenu"

        function toggle(): void {
            const open = !root.appleMenuOpen;
            root.closePopups();
            root.appleMenuOpen = open;
        }

        function about(): void {
            root.closePopups();
            root.aboutOpen = true;
        }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            const open = !root.controlCenterOpen;
            root.closePopups();
            root.controlCenterOpen = open;
        }
    }

    IpcHandler {
        target: "power"

        // power | shutdown | restart | logout
        function open(kind: string): void {
            root.closePopups();
            root.powerDialog = kind;
        }
    }

    IpcHandler {
        target: "missioncontrol"

        function toggle(): void {
            const open = !root.missionOpen;
            root.closePopups();
            root.missionOpen = open;
        }

        function open(): void {
            root.closePopups();
            root.missionOpen = true;
        }

        function close(): void {
            root.missionOpen = false;
        }
    }

    IpcHandler {
        target: "screenshot"

        function open(): void {
            root.closePopups();
            root.screenshotOpen = true;
        }

        function close(): void {
            root.screenshotOpen = false;
        }
    }
}
