import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Menu Apple (klik logo di kiri atas menu bar)
PanelWindow {
    id: root

    readonly property bool shown: Globals.appleMenuOpen
    readonly property string user: Quickshell.env("USER")

    function run(action): void {
        Globals.appleMenuOpen = false;
        action();
    }

    anchors.top: true
    anchors.left: true
    margins.top: 30
    margins.left: 8
    implicitWidth: 250
    implicitHeight: menu.height
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || menu.opacity > 0

    WlrLayershell.namespace: "macshell-menu"
    WlrLayershell.layer: WlrLayer.Overlay

    HyprlandFocusGrab {
        windows: [root]
        active: root.shown
        onCleared: Globals.appleMenuOpen = false
    }

    Glass {
        id: menu

        width: parent.width
        height: entries.implicitHeight + 10
        radius: 12
        tint: Qt.rgba(0.12, 0.12, 0.14, 0.55)
        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.shown ? 80 : 180
            }
        }

        Column {
            id: entries

            y: 5
            width: parent.width

            MenuEntry {
                text: "Tentang Komputer Ini"
                onTriggered: root.run(() => Globals.aboutOpen = true)
            }

            MenuEntry {
                text: "-"
            }

            MenuEntry {
                text: "Pengaturan Tampilan…"
                onTriggered: root.run(() => Quickshell.execDetached(["nwg-look"]))
            }

            MenuEntry {
                text: "Launchpad"
                shortcut: "⌘A"
                onTriggered: root.run(() => Globals.launchpadOpen = true)
            }

            MenuEntry {
                text: "-"
            }

            MenuEntry {
                text: "Paksa Keluar…"
                onTriggered: root.run(() => Quickshell.execDetached(["hyprctl", "kill"]))
            }

            MenuEntry {
                text: "-"
            }

            MenuEntry {
                text: "Tidurkan"
                onTriggered: root.run(() => Globals.power("suspend"))
            }

            MenuEntry {
                text: "Mulai Ulang…"
                onTriggered: root.run(() => Globals.powerDialog = "restart")
            }

            MenuEntry {
                text: "Matikan…"
                onTriggered: root.run(() => Globals.powerDialog = "shutdown")
            }

            MenuEntry {
                text: "-"
            }

            MenuEntry {
                text: "Kunci Layar"
                shortcut: "⌃⌘L"
                onTriggered: root.run(() => Globals.power("lock"))
            }

            MenuEntry {
                text: `Keluar ${root.user}…`
                onTriggered: root.run(() => Globals.powerDialog = "logout")
            }
        }
    }
}
