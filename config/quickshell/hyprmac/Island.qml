import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Dynamic Island di tengah menu bar.
//   diam      : pil hitam kecil
//   musik     : sampul album + gelombang suara
//   OSD       : volume / kecerahan saat diubah
//   hitung    : hitung mundur screenshot tertunda
//   hover     : kartu pemutar musik lengkap
PanelWindow {
    id: root

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property PwNode sink: Pipewire.defaultAudioSink

    property string osdKind: "" // "volume" | "brightness"
    property real osdValue: 0
    property bool osdMuted: false
    property bool armed: false // abaikan perubahan volume saat baru mulai
    property int countdown: 0

    readonly property string mode: countdown > 0 ? "countdown" : osdKind ? "osd" : (hover.hovered && player ? "expanded" : (playing ? "media" : "idle"))
    readonly property size target: ({
            idle: Qt.size(126, 24),
            media: Qt.size(250, 24),
            osd: Qt.size(290, 30),
            countdown: Qt.size(150, 30),
            expanded: Qt.size(400, 156)
        })[mode]

    function showOsd(kind: string, value: real, muted: bool): void {
        if (!armed)
            return;
        osdKind = kind;
        osdValue = Math.max(0, Math.min(1, value));
        osdMuted = muted;
        osdTimer.restart();
    }

    function formatTime(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    anchors.top: true
    implicitWidth: 460
    implicitHeight: 190
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "macshell-island"
    WlrLayershell.layer: WlrLayer.Overlay

    mask: Region {
        item: pill
    }

    Timer {
        running: true
        interval: 1500
        onTriggered: root.armed = true
    }

    Timer {
        id: countdownTimer
        interval: 1100
        onTriggered: root.countdown = 0
    }

    Timer {
        id: osdTimer
        interval: 1600
        onTriggered: root.osdKind = ""
    }

    // Posisi lagu tidak diperbarui otomatis oleh MPRIS
    Timer {
        running: root.playing && root.mode === "expanded"
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged(): void {
            root.showOsd("volume", root.sink.audio.volume, root.sink.audio.muted);
        }

        function onMutedChanged(): void {
            root.showOsd("volume", root.sink.audio.volume, root.sink.audio.muted);
        }
    }

    // Tombol kecerahan memanggil: qs -c hyprmac ipc call island brightness
    IpcHandler {
        target: "island"

        function brightness(): void {
            brightnessProc.running = true;
        }

        // Dipanggil tiap detik oleh screenshot.sh
        function countdown(seconds: int): void {
            root.countdown = seconds;
            countdownTimer.restart();
        }
    }

    Process {
        id: brightnessProc

        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const percent = parseInt(text.trim().split(",")[3]);
                if (!isNaN(percent))
                    root.showOsd("brightness", percent / 100, false);
            }
        }
    }

    Rectangle {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        y: 2
        width: root.target.width
        height: root.target.height
        radius: Math.min(height / 2, 34)
        color: "black"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        clip: true

        // Efek "membal" seperti Dynamic Island iPhone
        Behavior on width {
            SpringAnimation {
                spring: 3.2
                damping: 0.3
                epsilon: 0.25
            }
        }

        Behavior on height {
            SpringAnimation {
                spring: 3.2
                damping: 0.3
                epsilon: 0.25
            }
        }

        HoverHandler {
            id: hover
        }

        // ---------- Musik (ringkas) ----------
        Item {
            anchors.fill: parent
            opacity: root.mode === "media" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            ClippingRectangle {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 17
                height: 17
                radius: 5
                color: "#333"

                Image {
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Visualizer {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                active: root.playing && root.mode === "media"
            }
        }

        // ---------- Hitung mundur screenshot ----------
        Row {
            anchors.centerIn: parent
            spacing: 8
            opacity: root.mode === "countdown" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "timer"
                color: "#ff9f0a"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.countdown
                color: "white"
                font.family: "Adwaita Sans"
                font.pixelSize: 16
                font.weight: Font.Bold
            }
        }

        // ---------- OSD volume / kecerahan ----------
        Item {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            opacity: root.mode === "osd" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Text {
                id: osdIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.osdKind === "brightness" ? "light_mode" : (root.osdMuted || root.osdValue === 0 ? "volume_off" : (root.osdValue < 0.5 ? "volume_down" : "volume_up"))
                color: "white"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
            }

            Text {
                id: osdPercent

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                horizontalAlignment: Text.AlignRight
                text: root.osdMuted ? "0" : Math.round(root.osdValue * 100)
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: "Adwaita Sans"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Rectangle {
                anchors.left: osdIcon.right
                anchors.leftMargin: 10
                anchors.right: osdPercent.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 5
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.2)

                Rectangle {
                    width: parent.width * (root.osdMuted ? 0 : root.osdValue)
                    height: parent.height
                    radius: parent.radius
                    color: "white"

                    Behavior on width {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                }
            }
        }

        // ---------- Pemutar musik (diperbesar) ----------
        Item {
            anchors.fill: parent
            anchors.margins: 18
            opacity: root.mode === "expanded" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            ClippingRectangle {
                id: art

                width: 60
                height: 60
                radius: 14
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
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.verticalCenter: art.verticalCenter
                spacing: 3

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.player?.trackTitle || "Tidak ada judul"
                    color: "white"
                    font.family: "Adwaita Sans"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.player?.trackArtist || root.player?.identity || ""
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font.family: "Adwaita Sans"
                    font.pixelSize: 13
                }
            }

            // Progres lagu
            Item {
                id: progress

                anchors.top: art.bottom
                anchors.topMargin: 12
                width: parent.width
                height: 14
                visible: root.player?.lengthSupported ?? false

                Text {
                    id: elapsed

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.formatTime(root.player?.position ?? 0)
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.family: "Adwaita Sans"
                    font.pixelSize: 10
                }

                Text {
                    id: total

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.formatTime(root.player?.length ?? 0)
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.family: "Adwaita Sans"
                    font.pixelSize: 10
                }

                Rectangle {
                    anchors.left: elapsed.right
                    anchors.leftMargin: 8
                    anchors.right: total.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.2)

                    Rectangle {
                        width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                        height: parent.height
                        radius: parent.radius
                        color: "white"
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: root.player?.canSeek ?? false
                        onClicked: event => root.player.position = root.player.length * event.x / width
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -6
                spacing: 34

                Repeater {
                    model: [
                        { icon: "skip_previous", run: () => root.player?.previous(), size: 26 },
                        { icon: root.playing ? "pause" : "play_arrow", run: () => root.player?.togglePlaying(), size: 32 },
                        { icon: "skip_next", run: () => root.player?.next(), size: 26 }
                    ]

                    Text {
                        required property var modelData

                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.icon
                        color: controlMouse.pressed ? Qt.rgba(1, 1, 1, 0.6) : "white"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: modelData.size

                        MouseArea {
                            id: controlMouse

                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: parent.modelData.run()
                        }
                    }
                }
            }
        }
    }
}
