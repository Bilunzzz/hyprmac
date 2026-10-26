import QtQuick

// Slider tebal ala Control Center macOS (ikon di dalam track)
Item {
    id: root

    property real value: 0 // 0..1
    property string icon: ""
    signal moved(real value)

    implicitHeight: 28

    Rectangle {
        id: track

        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.14)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
        clip: true

        Rectangle {
            width: Math.max(track.height, track.width * root.value)
            height: parent.height
            radius: parent.radius
            color: Qt.rgba(1, 1, 1, 0.92)
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: "#3a3a3c"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 17
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true

        // Hanya memberi tahu; pemilik slider yang memperbarui `value`
        function update(x: real): void {
            root.moved(Math.max(0, Math.min(1, x / width)));
        }

        onPressed: event => update(event.x)
        onPositionChanged: event => update(event.x)
    }
}
