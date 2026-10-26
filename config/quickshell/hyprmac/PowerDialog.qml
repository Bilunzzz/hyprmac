import QtQuick
import Quickshell
import Quickshell.Wayland

// Dialog daya ala macOS.
//   shutdown / restart / logout : konfirmasi + hitung mundur 60 detik
//   power                       : pilihan Mulai Ulang / Tidur / Batal / Matikan
PanelWindow {
    id: root

    readonly property string kind: Globals.powerDialog
    readonly property bool shown: kind !== ""
    property int remaining: 60
    property string shownKind: "" // tetap terisi selama animasi tutup

    readonly property var info: ({
            shutdown: {
                title: "Anda yakin ingin mematikan komputer sekarang?",
                verb: "dimatikan",
                button: "Matikan",
                action: "shutdown",
                icon: "power_settings_new"
            },
            restart: {
                title: "Anda yakin ingin memulai ulang komputer sekarang?",
                verb: "dimulai ulang",
                button: "Mulai Ulang",
                action: "reboot",
                icon: "restart_alt"
            },
            logout: {
                title: `Anda yakin ingin keluar dari semua aplikasi dan log out?`,
                verb: "log out",
                button: "Log Out",
                action: "exit",
                icon: "logout"
            },
            power: {
                title: "Anda yakin ingin mematikan komputer?",
                icon: "power_settings_new"
            }
        })[shownKind] ?? {}

    function close(): void {
        Globals.powerDialog = "";
    }

    function confirm(action: string): void {
        close();
        Globals.power(action);
    }

    onShownChanged: {
        if (shown) {
            shownKind = kind;
            remaining = 60;
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
    visible: shown || dialog.opacity > 0

    WlrLayershell.namespace: "macshell-dialog"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Timer {
        running: root.shown && root.shownKind !== "power"
        interval: 1000
        repeat: true
        onTriggered: {
            root.remaining -= 1;
            if (root.remaining <= 0)
                root.confirm(root.info.action);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.25)
        opacity: dialog.opacity

        MouseArea {
            anchors.fill: parent
        }
    }

    Item {
        id: focusItem

        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onReturnPressed: {
            if (root.shownKind === "power")
                root.confirm("shutdown");
            else
                root.confirm(root.info.action);
        }
    }

    Glass {
        id: dialog

        anchors.centerIn: parent
        width: 300
        height: body.implicitHeight + 40
        radius: 24
        tint: Qt.rgba(0.13, 0.13, 0.15, 0.62)
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.92

        Behavior on opacity {
            NumberAnimation {
                duration: 180
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutBack
            }
        }

        Column {
            id: body

            x: 20
            y: 20
            width: parent.width - 40
            spacing: 10

            // Ikon dalam lingkaran kaca
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 64
                height: 64
                radius: 16
                gradient: Gradient {
                    GradientStop { position: 0; color: "#5a5a60" }
                    GradientStop { position: 1; color: "#2c2c30" }
                }
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: root.info.icon ?? ""
                    color: "white"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 36
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.info.title ?? ""
                color: "white"
                font.family: "Adwaita Sans"
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            Text {
                visible: root.shownKind !== "power"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: `Jika Anda tidak melakukan apa pun, komputer akan ${root.info.verb ?? ""} otomatis dalam ${root.remaining} detik.`
                color: Qt.rgba(1, 1, 1, 0.75)
                font.family: "Adwaita Sans"
                font.pixelSize: 12
            }

            Item {
                width: 1
                height: 4
            }

            // Konfirmasi: Batal | Aksi
            Row {
                visible: root.shownKind !== "power"
                width: parent.width
                spacing: 10

                DialogButton {
                    width: (parent.width - 10) / 2
                    text: "Batal"
                    onClicked: root.close()
                }

                DialogButton {
                    width: (parent.width - 10) / 2
                    text: root.info.button ?? ""
                    primary: true
                    onClicked: root.confirm(root.info.action)
                }
            }

            // Pilihan daya: Mulai Ulang | Tidur, lalu Batal | Matikan
            Grid {
                visible: root.shownKind === "power"
                width: parent.width
                columns: 2
                spacing: 10

                DialogButton {
                    width: (parent.width - 10) / 2
                    text: "Mulai Ulang"
                    onClicked: root.confirm("reboot")
                }

                DialogButton {
                    width: (parent.width - 10) / 2
                    text: "Tidur"
                    onClicked: root.confirm("suspend")
                }

                DialogButton {
                    width: (parent.width - 10) / 2
                    text: "Batal"
                    onClicked: root.close()
                }

                DialogButton {
                    width: (parent.width - 10) / 2
                    text: "Matikan"
                    primary: true
                    onClicked: root.confirm("shutdown")
                }
            }
        }
    }
}
