import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// "Tentang Komputer Ini" ala "About This Mac"
PanelWindow {
    id: root

    readonly property bool shown: Globals.aboutOpen
    property var info: ({})
    property string version: ""

    // Nama perangkat keras dipendekkan seperti di macOS ("Apple M3 Pro", "16 GB")
    function shortCpu(raw: string): string {
        return raw.replace(/\(R\)|\(TM\)/g, "").replace(/^\d+(st|nd|rd|th) Gen /, "").replace(/ @.*$/, "").replace(/ CPU$/, "").trim();
    }

    function shortGpu(raw: string): string {
        const vendor = raw.split(" ")[0];
        const name = raw.match(/\[(.*)\]/)?.[1] ?? raw.replace(/ \(rev.*$/, "");
        return `${vendor} ${name}`;
    }

    function close(): void {
        Globals.aboutOpen = false;
    }

    onShownChanged: {
        if (shown) {
            infoProc.running = true;
            focusItem.forceActiveFocus();
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || card.opacity > 0

    WlrLayershell.namespace: "macshell-dialog"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // key=value per baris, dirapikan di onStreamFinished
    Process {
        id: infoProc

        command: ["sh", "-c", ". /etc/os-release
            echo \"os=$PRETTY_NAME\"
            echo \"logo=${LOGO:-distributor-logo}\"
            echo \"vendor=$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null)\"
            echo \"model=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)\"
            echo \"year=$(cut -d/ -f3 /sys/devices/virtual/dmi/id/bios_date 2>/dev/null)\"
            echo \"cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2-)\"
            echo \"mem=$(awk '/MemTotal/{print $2}' /proc/meminfo)\"
            lspci 2>/dev/null | grep -iE 'vga|3d' | sed 's/.*: /gpu=/; s/ Corporation//'
            echo \"kernel=$(uname -r)\"
            echo \"host=$(cat /etc/hostname)\"
            echo \"wm=$(hyprctl version 2>/dev/null | head -1 | cut -d' ' -f1-2)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const info = { gpus: [] };
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("=");
                    const key = line.slice(0, i);
                    const value = line.slice(i + 1).trim();
                    if (key === "gpu")
                        info.gpus.push(root.shortGpu(value));
                    else
                        info[key] = value;
                }
                info.cpu = root.shortCpu(info.cpu ?? "");
                info.mem = `${Math.ceil(parseInt(info.mem) / 1024 / 1024)} GB`;
                info.kernel = (info.kernel ?? "").replace(/-.*$/, "");
                root.info = info;
            }
        }
    }

    // Versi hyprmac (file VERSION disalin oleh install.sh)
    FileView {
        path: Quickshell.shellPath("VERSION")
        onLoaded: root.version = text().trim()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        id: focusItem

        focus: true
        Keys.onEscapePressed: root.close()
    }

    Glass {
        id: card

        anchors.centerIn: parent
        width: 330
        height: content.implicitHeight + 72
        radius: 24
        tint: Qt.rgba(0.13, 0.13, 0.15, 0.68)
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.94

        Behavior on opacity {
            NumberAnimation {
                duration: 180
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        // Klik di dalam kartu tidak menutupnya
        MouseArea {
            anchors.fill: parent
        }

        // Traffic light: hanya tombol tutup yang aktif, seperti macOS
        Row {
            x: 14
            y: 14
            spacing: 8

            Repeater {
                model: ["#ff5f57", "#4a4a4e", "#4a4a4e"]

                Rectangle {
                    required property string modelData
                    required property int index

                    width: 12
                    height: 12
                    radius: 6
                    color: modelData

                    MouseArea {
                        enabled: parent.index === 0
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: root.close()
                    }
                }
            }
        }

        Column {
            id: content

            y: 44
            width: parent.width
            spacing: 0

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 104
                height: 104
                source: Quickshell.iconPath(root.info.logo ?? "distributor-logo", "computer")
                sourceSize: Qt.size(208, 208)
                smooth: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 16
                text: root.info.model ?? ""
                color: "white"
                font.family: "Adwaita Sans"
                font.pixelSize: 22
                font.weight: Font.Bold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 2
                text: [root.info.vendor, root.info.year].filter(s => s).join(", ")
                color: Qt.rgba(1, 1, 1, 0.55)
                font.family: "Adwaita Sans"
                font.pixelSize: 12
            }

            // Label rata kanan | nilai rata kiri, satu baris per nilai
            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 20
                columns: 2
                columnSpacing: 10
                rowSpacing: 5

                Repeater {
                    model: [
                        ["Chip", root.info.cpu],
                        ["Memori", root.info.mem],
                        ["Grafis", root.info.gpus?.[0]],
                        ["", root.info.gpus?.[1]],
                        ["Sistem", root.info.os ? `${root.info.os} ${root.info.kernel}` : ""],
                        ["Nama", root.info.host]
                    ].filter(r => r[1]).reduce((cells, r) => cells.concat(r), [])

                    Text {
                        required property string modelData
                        required property int index

                        readonly property bool isLabel: index % 2 === 0

                        width: isLabel ? 62 : 205
                        horizontalAlignment: isLabel ? Text.AlignRight : Text.AlignLeft
                        elide: Text.ElideRight
                        text: modelData
                        color: isLabel ? "white" : Qt.rgba(1, 1, 1, 0.65)
                        font.family: "Adwaita Sans"
                        font.pixelSize: 12
                        font.weight: isLabel ? Font.DemiBold : Font.Normal
                    }
                }
            }

            Item {
                width: 1
                height: 20
            }

            DialogButton {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 120
                height: 28
                text: "Info Lainnya…"
                onClicked: {
                    root.close();
                    Quickshell.execDetached(["kitty", "--hold", "fastfetch"]);
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 14
                text: [root.version ? `hyprmac v${root.version}` : "", root.info.wm, "i use arch btw"].filter(s => s).join(" · ")
                color: Qt.rgba(1, 1, 1, 0.35)
                font.family: "Adwaita Sans"
                font.pixelSize: 10
            }
        }
    }
}
