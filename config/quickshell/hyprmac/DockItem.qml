import QtQuick
import Quickshell

Item {
    id: item

    required property var modelData
    required property int index
    required property var dock

    // Data terbaru untuk aplikasi ini (modelData bisa tertinggal saat jendela berubah)
    readonly property var app: dock.apps.find(a => a.key === modelData.key) ?? modelData
    readonly property bool separator: app.separator ?? false
    readonly property bool running: app.toplevels.length > 0

    readonly property real distance: Math.abs(dock.pointerX - (dock.baseCenters[index] ?? -99999))
    readonly property real zoom: separator || distance >= dock.influence ? 1 : 1 + (dock.maxZoom - 1) * (Math.cos(distance / dock.influence * Math.PI) + 1) / 2

    width: separator ? dock.separatorWidth : dock.iconSize * zoom
    height: separator ? dock.iconSize : dock.iconSize * zoom
    y: parent.height - height

    Behavior on width {
        NumberAnimation {
            duration: item.dock.zooming ? 70 : 220
            easing.type: Easing.OutQuad
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: item.dock.zooming ? 70 : 220
            easing.type: Easing.OutQuad
        }
    }

    onRunningChanged: {
        if (running) {
            bounce.stop();
            lift.y = 0;
        }
    }

    // Pemisah antara aplikasi tersemat dan yang tidak
    Rectangle {
        visible: item.separator
        anchors.centerIn: parent
        width: 1
        height: parent.height * 0.75
        color: Qt.rgba(1, 1, 1, 0.3)
    }

    Image {
        id: icon

        visible: !item.separator
        anchors.fill: parent
        source: item.separator ? "" : Quickshell.iconPath(item.app.icon, "application-x-executable")
        sourceSize: Qt.size(128, 128)
        smooth: true
        mipmap: true
        scale: mouse.pressed ? 0.88 : 1

        transform: Translate {
            id: lift
        }

        Behavior on scale {
            NumberAnimation {
                duration: 120
            }
        }
    }

    // Pantulan saat aplikasi sedang dibuka
    SequentialAnimation {
        id: bounce

        loops: 3

        NumberAnimation {
            target: lift
            property: "y"
            to: -item.dock.iconSize * 0.4
            duration: 260
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: lift
            property: "y"
            to: 0
            duration: 260
            easing.type: Easing.InQuad
        }
    }

    // Titik di bawah aplikasi yang berjalan
    Rectangle {
        visible: item.running && !item.separator
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 2
        width: 4
        height: 4
        radius: 2
        color: Qt.rgba(1, 1, 1, 0.85)
    }

    // Nama aplikasi di atas ikon
    Glass {
        id: label

        visible: opacity > 0
        opacity: mouse.containsMouse && !item.separator ? 1 : 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 10
        width: labelText.implicitWidth + 22
        height: labelText.implicitHeight + 10
        radius: height / 2
        tint: Qt.rgba(0.12, 0.12, 0.14, 0.75)

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }

        Text {
            id: labelText

            anchors.centerIn: parent
            text: item.app.name ?? ""
            color: "white"
            font.family: "Adwaita Sans"
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: mouse

        enabled: !item.separator
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: event => {
            // Klik tengah: buka jendela baru
            if (event.button === Qt.MiddleButton && item.app.entry) {
                item.app.entry.execute();
                return;
            }
            if (!item.running && !item.app.launchpad)
                bounce.start();
            item.dock.activate(item.app);
        }
    }
}
