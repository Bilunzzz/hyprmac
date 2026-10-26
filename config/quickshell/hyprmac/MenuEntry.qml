import QtQuick

// Satu baris menu ala macOS: sorotan biru saat diarahkan, teks pintasan di kanan.
// `text: "-"` menjadi garis pemisah.
Item {
    id: root

    property string text: ""
    property string shortcut: ""
    property bool checked: false
    property bool showCheck: false
    signal triggered

    readonly property bool separator: text === "-"

    width: parent?.width ?? 200
    height: separator ? 11 : 24

    Rectangle {
        visible: root.separator
        anchors.verticalCenter: parent.verticalCenter
        x: 10
        width: parent.width - 20
        height: 1
        color: Qt.rgba(1, 1, 1, 0.14)
    }

    Rectangle {
        visible: !root.separator
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        radius: 6
        color: mouse.containsMouse ? "#0a84ff" : "transparent"

        Text {
            visible: root.showCheck && root.checked
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "check"
            color: "white"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 14
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: root.showCheck ? 24 : 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: "white"
            font.family: "Adwaita Sans"
            font.pixelSize: 13
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.shortcut
            color: mouse.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.45)
            font.family: "Adwaita Sans"
            font.pixelSize: 12
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.triggered()
        }
    }
}
