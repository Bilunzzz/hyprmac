import QtQuick

// Gelombang suara kecil di Dynamic Island (animasi, bukan analisis audio)
Row {
    id: root

    property bool active: false

    spacing: 2.5
    height: 14

    Repeater {
        model: 5

        Rectangle {
            id: bar

            required property int index

            anchors.verticalCenter: parent.verticalCenter
            width: 2.5
            height: 4
            radius: 1.25
            color: Qt.hsla(0.53 + index * 0.02, 0.85, 0.65, 1)

            Behavior on height {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutQuad
                }
            }

            Timer {
                running: root.active
                repeat: true
                interval: 150 + bar.index * 23
                onTriggered: bar.height = 4 + Math.random() * 10
                onRunningChanged: if (!running) bar.height = 4
            }
        }
    }
}
