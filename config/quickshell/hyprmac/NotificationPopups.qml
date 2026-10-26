import QtQuick
import Quickshell
import Quickshell.Wayland

// Notifikasi yang baru masuk, meluncur dari kanan di bawah menu bar
PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    margins.top: 34
    margins.right: 10
    implicitWidth: 380
    implicitHeight: 600
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "macshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    mask: Region {
        item: stack.contentItem
    }

    ListView {
        id: stack

        anchors.fill: parent
        anchors.margins: 8
        spacing: 10
        interactive: false
        model: ScriptModel {
            values: [...Notifs.popups]
        }

        delegate: NotificationCard {
            required property var modelData

            notification: modelData
            popup: true
            width: stack.width
        }

        add: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 400
                    to: 0
                    duration: 420
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.8
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 250
                }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    to: 400
                    duration: 260
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: 260
                }
            }
        }

        displaced: Transition {
            NumberAnimation {
                property: "y"
                duration: 260
                easing.type: Easing.OutCubic
            }
        }
    }
}
