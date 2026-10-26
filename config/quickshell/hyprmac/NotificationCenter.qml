import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Notification Center ala macOS: widget kalender + riwayat notifikasi,
// meluncur masuk dari kanan (klik jam di menu bar)
PanelWindow {
    id: root

    readonly property bool shown: Notifs.centerOpen
    property real slide: shown ? 1 : 0 // 0 = tersembunyi di kanan

    Behavior on slide {
        NumberAnimation {
            duration: 380
            easing.type: Easing.OutCubic
        }
    }

    anchors.top: true
    anchors.bottom: true
    anchors.right: true
    margins.top: 34
    margins.bottom: 8
    implicitWidth: 400
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: slide > 0.001

    WlrLayershell.namespace: "macshell-center"
    WlrLayershell.layer: WlrLayer.Overlay

    mask: Region {
        item: panel
    }

    // Klik di luar panel menutupnya
    HyprlandFocusGrab {
        windows: [root]
        active: root.shown
        onCleared: Notifs.centerOpen = false
    }

    Glass {
        id: panel

        x: 10 + (1 - root.slide) * (root.width + 20)
        width: parent.width - 20
        height: parent.height
        radius: 28
        tint: Qt.rgba(0.10, 0.10, 0.12, 0.40)

        Column {
            id: top

            x: 16
            y: 16
            width: parent.width - 32
            spacing: 12

            CalendarWidget {
                width: parent.width
            }

            // Judul daftar notifikasi
            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifikasi"
                    color: "white"
                    font.family: "Adwaita Sans"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                Glass {
                    visible: Notifs.list.length > 0
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: clearText.implicitWidth + 22
                    height: 24
                    radius: 12
                    tint: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        id: clearText

                        anchors.centerIn: parent
                        text: "Hapus semua"
                        color: "white"
                        font.family: "Adwaita Sans"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Notifs.clearAll()
                    }
                }
            }
        }

        ListView {
            id: list

            anchors.top: top.bottom
            anchors.topMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            x: 16
            width: parent.width - 32
            spacing: 10
            clip: true
            model: ScriptModel {
                values: [...Notifs.list].reverse()
            }

            delegate: NotificationCard {
                required property var modelData

                notification: modelData
                width: list.width
            }

            remove: Transition {
                NumberAnimation {
                    property: "x"
                    to: 380
                    duration: 220
                    easing.type: Easing.InCubic
                }
            }

            displaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                visible: list.count === 0
                anchors.horizontalCenter: parent.horizontalCenter
                y: 30
                text: "Tidak ada notifikasi"
                color: Qt.rgba(1, 1, 1, 0.5)
                font.family: "Adwaita Sans"
                font.pixelSize: 13
            }
        }
    }
}
