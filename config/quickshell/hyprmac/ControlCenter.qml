import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Control Center ala macOS: dropdown di kanan atas (ikon dua sakelar di menu bar)
PanelWindow {
    id: root

    readonly property bool shown: Globals.controlCenterOpen
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    property bool wifiOn: true
    property string ssid: ""
    property real brightness: 0.5

    onShownChanged: {
        if (shown) {
            wifiProc.running = true;
            brightnessProc.running = true;
        }
    }

    anchors.top: true
    anchors.right: true
    margins.top: 30
    margins.right: 8
    implicitWidth: 330
    implicitHeight: panel.height
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || panel.opacity > 0

    WlrLayershell.namespace: "macshell-center"
    WlrLayershell.layer: WlrLayer.Overlay

    HyprlandFocusGrab {
        windows: [root]
        active: root.shown
        onCleared: Globals.controlCenterOpen = false
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    // Baris 1: status radio; baris berikutnya: SSID yang tersambung
    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.wifiOn = l[0] === "enabled";
                root.ssid = l[1] ?? "";
            }
        }
    }

    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const percent = parseInt(text.trim().split(",")[3]);
                if (!isNaN(percent))
                    root.brightness = percent / 100;
            }
        }
    }

    Glass {
        id: panel

        width: parent.width
        height: column.implicitHeight + 24
        radius: 26
        tint: Qt.rgba(0.11, 0.11, 0.13, 0.45)
        opacity: root.shown ? 1 : 0
        transform: Translate {
            y: root.shown ? 0 : -8

            Behavior on y {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }

        Column {
            id: column

            x: 12
            y: 12
            width: parent.width - 24
            spacing: 10

            Row {
                width: parent.width
                spacing: 10

                // Tile koneksi: Wi-Fi, Bluetooth, Fokus
                Glass {
                    width: (parent.width - 10) * 0.58
                    height: 150
                    radius: 20
                    tint: Qt.rgba(1, 1, 1, 0.05)

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Repeater {
                            model: [
                                {
                                    icon: root.wifiOn ? "wifi" : "wifi_off",
                                    label: "Wi-Fi",
                                    sub: root.wifiOn ? (root.ssid || "Tidak tersambung") : "Mati",
                                    on: root.wifiOn,
                                    run: () => {
                                        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"]);
                                        root.wifiOn = !root.wifiOn;
                                    }
                                },
                                {
                                    icon: "bluetooth",
                                    label: "Bluetooth",
                                    sub: (Bluetooth.defaultAdapter?.enabled ?? false) ? "Nyala" : "Mati",
                                    on: Bluetooth.defaultAdapter?.enabled ?? false,
                                    run: () => {
                                        if (Bluetooth.defaultAdapter)
                                            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                                    }
                                },
                                {
                                    icon: "do_not_disturb_on",
                                    label: "Fokus",
                                    sub: Notifs.dnd ? "Jangan Ganggu" : "Mati",
                                    on: Notifs.dnd,
                                    run: () => Notifs.dnd = !Notifs.dnd
                                }
                            ]

                            Row {
                                id: toggleRow

                                required property var modelData

                                spacing: 9

                                Rectangle {
                                    width: 34
                                    height: 34
                                    radius: 17
                                    color: toggleRow.modelData.on ? "#0a84ff" : Qt.rgba(1, 1, 1, 0.16)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: toggleRow.modelData.icon
                                        color: "white"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 18
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: toggleRow.modelData.run()
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: toggleRow.modelData.label
                                        color: "white"
                                        font.family: "Adwaita Sans"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        width: 90
                                        elide: Text.ElideRight
                                        text: toggleRow.modelData.sub
                                        color: Qt.rgba(1, 1, 1, 0.6)
                                        font.family: "Adwaita Sans"
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }
                    }
                }

                // Dua tile kecil: Screenshot dan Kunci Layar
                Column {
                    width: (parent.width - 10) * 0.42
                    spacing: 10

                    Repeater {
                        model: [
                            {
                                icon: "screenshot_region",
                                label: "Screenshot",
                                run: () => {
                                    Globals.controlCenterOpen = false;
                                    Globals.screenshotOpen = true;
                                }
                            },
                            {
                                icon: "lock",
                                label: "Kunci Layar",
                                run: () => {
                                    Globals.controlCenterOpen = false;
                                    Globals.power("lock");
                                }
                            }
                        ]

                        Glass {
                            id: smallTile

                            required property var modelData

                            width: parent.width
                            height: 70
                            radius: 20
                            tint: Qt.rgba(1, 1, 1, tileMouse.containsMouse ? 0.1 : 0.05)

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: smallTile.modelData.icon
                                    color: "white"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 22
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: smallTile.modelData.label
                                    color: "white"
                                    font.family: "Adwaita Sans"
                                    font.pixelSize: 11
                                }
                            }

                            MouseArea {
                                id: tileMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: smallTile.modelData.run()
                            }
                        }
                    }
                }
            }

            // Layar & Suara
            Repeater {
                model: ["display", "sound"]

                Glass {
                    id: sliderTile

                    required property string modelData

                    width: column.width
                    height: 64
                    radius: 20
                    tint: Qt.rgba(1, 1, 1, 0.05)

                    Text {
                        x: 14
                        y: 9
                        text: sliderTile.modelData === "display" ? "Layar" : "Suara"
                        color: "white"
                        font.family: "Adwaita Sans"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Slider {
                        x: 12
                        y: 28
                        width: parent.width - 24
                        icon: sliderTile.modelData === "display" ? "light_mode" : ((root.sink?.audio?.muted ?? false) ? "volume_off" : "volume_up")
                        value: sliderTile.modelData === "display" ? root.brightness : (root.sink?.audio?.volume ?? 0)
                        onMoved: v => {
                            if (sliderTile.modelData === "display") {
                                root.brightness = v;
                                Quickshell.execDetached(["brightnessctl", "-q", "s", Math.max(1, Math.round(v * 100)) + "%"]);
                            } else if (root.sink?.audio) {
                                root.sink.audio.muted = false;
                                root.sink.audio.volume = v;
                            }
                        }
                    }
                }
            }

            // Sedang diputar
            Glass {
                visible: root.player !== null
                width: column.width
                height: 64
                radius: 20
                tint: Qt.rgba(1, 1, 1, 0.05)

                ClippingRectangle {
                    id: art

                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 44
                    radius: 10
                    color: "#333"

                    Image {
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                Column {
                    anchors.left: art.right
                    anchors.leftMargin: 10
                    anchors.right: controls.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.player?.trackTitle || "Tidak ada judul"
                        color: "white"
                        font.family: "Adwaita Sans"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.player?.trackArtist || root.player?.identity || ""
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.family: "Adwaita Sans"
                        font.pixelSize: 11
                    }
                }

                Row {
                    id: controls

                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Repeater {
                        model: [
                            { icon: "skip_previous", run: () => root.player?.previous() },
                            { icon: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow", run: () => root.player?.togglePlaying() },
                            { icon: "skip_next", run: () => root.player?.next() }
                        ]

                        Text {
                            required property var modelData

                            text: modelData.icon
                            color: "white"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 24

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                onClicked: parent.modelData.run()
                            }
                        }
                    }
                }
            }
        }
    }
}
