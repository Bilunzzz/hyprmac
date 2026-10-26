import QtQuick
import Quickshell
import Quickshell.Wayland

// Toolbar screenshot ala macOS (⌘⇧5): pilih seluruh layar / jendela / area,
// Langsung atau Tunda, tujuan simpan, lalu Ambil.
PanelWindow {
    id: root

    readonly property bool shown: Globals.screenshotOpen
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/screenshot.sh"

    property string mode: "area" // screen | window | area
    property bool delayed: false
    property int delay: 5
    property string dest: "save" // save | clipboard | edit
    property bool optionsOpen: false
    property string hint: ""

    readonly property var modes: [
        { id: "screen", icon: "screenshot_monitor", label: "Ambil Seluruh Layar" },
        { id: "window", icon: "select_window", label: "Ambil Jendela Terpilih" },
        { id: "area", icon: "screenshot_region", label: "Ambil Bagian Terpilih" }
    ]

    function close(): void {
        optionsOpen = false;
        Globals.screenshotOpen = false;
    }

    function capture(): void {
        close();
        // Tunggu toolbar hilang dulu supaya tidak ikut terfoto
        startTimer.restart();
    }

    onShownChanged: {
        if (shown)
            focusItem.forceActiveFocus();
    }

    anchors.bottom: true
    margins.bottom: 110
    implicitWidth: 700
    implicitHeight: 330
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || bar.opacity > 0

    WlrLayershell.namespace: "macshell-screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: bar

        Region {
            item: root.optionsOpen ? options : null
        }

        Region {
            item: hintBox
        }
    }

    Timer {
        id: startTimer
        interval: 300
        onTriggered: Quickshell.execDetached([root.script, root.mode, root.dest, String(root.delayed ? root.delay : 0)])
    }

    Item {
        id: focusItem

        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onReturnPressed: root.capture()
        Keys.onEnterPressed: root.capture()
    }

    // Keterangan tombol yang sedang diarahkan
    Glass {
        id: hintBox

        anchors.horizontalCenter: bar.horizontalCenter
        anchors.bottom: bar.top
        anchors.bottomMargin: 10
        width: hintText.implicitWidth + 24
        height: 26
        radius: 13
        tint: Qt.rgba(0.12, 0.12, 0.14, 0.7)
        opacity: root.hint && !root.optionsOpen && root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }

        Text {
            id: hintText

            anchors.centerIn: parent
            text: root.hint
            color: "white"
            font.family: "Adwaita Sans"
            font.pixelSize: 12
        }
    }

    Glass {
        id: bar

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: row.implicitWidth + 16
        height: 54
        radius: 16
        tint: Qt.rgba(0.12, 0.12, 0.14, 0.55)
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.96

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: row

            anchors.centerIn: parent
            spacing: 6

            // Tutup
            ToolButton {
                icon: "close"
                size: 30
                iconSize: 16
                round: true
                onHoveredChanged: root.hint = hovered ? "Tutup" : ""
                onClicked: root.close()
            }

            Divider {}

            Repeater {
                model: root.modes

                ToolButton {
                    required property var modelData

                    icon: modelData.icon
                    selected: root.mode === modelData.id
                    onHoveredChanged: root.hint = hovered ? modelData.label : ""
                    onClicked: root.mode = modelData.id
                }
            }

            Divider {}

            // Langsung | Tunda
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: segment.implicitWidth + 6
                height: 30
                radius: 9
                color: Qt.rgba(1, 1, 1, 0.08)

                Row {
                    id: segment

                    anchors.centerIn: parent
                    spacing: 0

                    Repeater {
                        model: [
                            { delayed: false, label: "Langsung" },
                            { delayed: true, label: `Tunda ${root.delay} dtk` }
                        ]

                        Rectangle {
                            id: seg

                            required property var modelData

                            width: segLabel.implicitWidth + 22
                            height: 24
                            radius: 7
                            color: root.delayed === modelData.delayed ? Qt.rgba(1, 1, 1, 0.25) : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            Text {
                                id: segLabel

                                anchors.centerIn: parent
                                text: seg.modelData.label
                                color: "white"
                                font.family: "Adwaita Sans"
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.delayed = seg.modelData.delayed
                            }
                        }
                    }
                }
            }

            // Opsi ▾
            Rectangle {
                id: optionsButton

                anchors.verticalCenter: parent.verticalCenter
                width: optionsRow.implicitWidth + 16
                height: 30
                radius: 9
                color: root.optionsOpen || optionsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"

                Row {
                    id: optionsRow

                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Opsi"
                        color: "white"
                        font.family: "Adwaita Sans"
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "expand_more"
                        color: "white"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                    }
                }

                MouseArea {
                    id: optionsMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.optionsOpen = !root.optionsOpen
                }
            }

            // Ambil
            DialogButton {
                anchors.verticalCenter: parent.verticalCenter
                width: 74
                height: 32
                text: "Ambil"
                primary: true
                onClicked: root.capture()
            }
        }
    }

    // Menu Opsi, muncul di atas tombolnya
    Glass {
        id: options

        visible: opacity > 0
        opacity: root.optionsOpen && root.shown ? 1 : 0
        x: bar.x + optionsButton.x + 8 + optionsButton.width / 2 - width / 2
        anchors.bottom: bar.top
        anchors.bottomMargin: 8
        width: 210
        height: optionsColumn.implicitHeight + 10
        radius: 12
        tint: Qt.rgba(0.12, 0.12, 0.14, 0.7)

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }

        Column {
            id: optionsColumn

            y: 5
            width: parent.width

            SectionLabel {
                text: "Simpan ke"
            }

            Repeater {
                model: [
                    { id: "save", label: "Gambar" },
                    { id: "clipboard", label: "Papan Klip" },
                    { id: "edit", label: "Buka di Editor" }
                ]

                MenuEntry {
                    required property var modelData

                    text: modelData.label
                    showCheck: true
                    checked: root.dest === modelData.id
                    onTriggered: root.dest = modelData.id
                }
            }

            MenuEntry {
                text: "-"
            }

            SectionLabel {
                text: "Penundaan (Tunda)"
            }

            Repeater {
                model: [5, 10, 20]

                MenuEntry {
                    required property int modelData

                    text: `${modelData} Detik`
                    showCheck: true
                    checked: root.delay === modelData
                    onTriggered: {
                        root.delay = modelData;
                        root.delayed = true;
                    }
                }
            }
        }
    }

    component SectionLabel: Text {
        x: 15
        height: 22
        verticalAlignment: Text.AlignVCenter
        color: Qt.rgba(1, 1, 1, 0.5)
        font.family: "Adwaita Sans"
        font.pixelSize: 11
        font.weight: Font.DemiBold
    }

    component Divider: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: 26
        color: Qt.rgba(1, 1, 1, 0.15)
    }

    component ToolButton: Rectangle {
        id: tool

        property string icon
        property bool selected: false
        property bool round: false
        property int size: 38
        property int iconSize: 22
        readonly property bool hovered: toolMouse.containsMouse
        signal clicked

        anchors.verticalCenter: parent.verticalCenter
        width: size
        height: size
        radius: round ? size / 2 : 9
        color: selected ? Qt.rgba(1, 1, 1, 0.25) : (hovered ? Qt.rgba(1, 1, 1, 0.12) : (round ? Qt.rgba(1, 1, 1, 0.1) : "transparent"))

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Text {
            anchors.centerIn: parent
            text: tool.icon
            color: "white"
            font.family: "Material Symbols Rounded"
            font.pixelSize: tool.iconSize
        }

        MouseArea {
            id: toolMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: tool.clicked()
        }
    }
}
