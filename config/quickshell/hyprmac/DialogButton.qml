import QtQuick

// Tombol kapsul ala macOS Tahoe: abu-abu kaca, atau biru untuk aksi utama
Rectangle {
    id: root

    property string text: ""
    property bool primary: false
    signal clicked

    height: 30
    radius: height / 2
    color: primary ? (mouse.pressed ? "#0063d1" : "#0a84ff") : Qt.rgba(1, 1, 1, mouse.pressed ? 0.28 : (mouse.containsMouse ? 0.2 : 0.14))
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, primary ? 0.25 : 0.12)

    Text {
        anchors.centerIn: parent
        text: root.text
        color: "white"
        font.family: "Adwaita Sans"
        font.pixelSize: 13
        font.weight: root.primary ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
