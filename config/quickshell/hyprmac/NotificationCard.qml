import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Kartu notifikasi liquid glass (dipakai di popup dan Notification Center)
Glass {
    id: card

    required property Notification notification
    property bool popup: false

    readonly property string iconSource: {
        const n = notification;
        if (!n)
            return "";
        if (n.image)
            return n.image;
        const icon = n.appIcon || DesktopEntries.heuristicLookup(n.desktopEntry || n.appName)?.icon || "";
        if (icon.startsWith("/") || icon.startsWith("file:"))
            return icon;
        return Quickshell.iconPath(icon || "dialog-information", "dialog-information");
    }

    width: parent?.width ?? 360
    height: content.implicitHeight + 24
    radius: 22
    tint: Qt.rgba(0.11, 0.11, 0.13, 0.42)
    sheen: hover.hovered ? 0.14 : 0.10

    HoverHandler {
        id: hover
    }

    // Popup hilang sendiri, ditahan selama kursor di atasnya
    Timer {
        running: card.popup && !hover.hovered && (card.notification?.urgency ?? 0) !== NotificationUrgency.Critical
        interval: (card.notification?.expireTimeout ?? 0) > 0 ? card.notification.expireTimeout : 5000
        onTriggered: Notifs.removePopup(card.notification)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Notifs.activate(card.notification)
    }

    Row {
        id: content

        x: 12
        y: 12
        width: parent.width - 24
        spacing: 11

        ClippingRectangle {
            width: 38
            height: 38
            radius: 9
            color: "transparent"

            Image {
                anchors.fill: parent
                source: card.iconSource
                sourceSize: Qt.size(76, 76)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Column {
            width: parent.width - 49
            spacing: 2

            Item {
                width: parent.width
                height: appName.implicitHeight

                Text {
                    id: appName

                    anchors.left: parent.left
                    anchors.right: when.left
                    anchors.rightMargin: 8
                    elide: Text.ElideRight
                    text: card.notification?.appName ?? ""
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font.family: "Adwaita Sans"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                }

                Text {
                    id: when

                    anchors.right: parent.right
                    visible: !hover.hovered
                    text: card.notification ? Notifs.ago(card.notification) : ""
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.family: "Adwaita Sans"
                    font.pixelSize: 11
                }
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: card.notification?.summary ?? ""
                color: "white"
                font.family: "Adwaita Sans"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                visible: text !== ""
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                textFormat: Text.StyledText
                text: card.notification?.body ?? ""
                color: Qt.rgba(1, 1, 1, 0.85)
                font.family: "Adwaita Sans"
                font.pixelSize: 13
            }

            // Tombol aksi (selain aksi default)
            Row {
                visible: actionRepeater.count > 0
                topPadding: 6
                spacing: 6

                Repeater {
                    id: actionRepeater

                    model: (card.notification?.actions ?? []).filter(a => a.identifier !== "default")

                    Glass {
                        required property var modelData

                        width: actionText.implicitWidth + 20
                        height: 26
                        radius: 13
                        tint: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: actionText

                            anchors.centerIn: parent
                            text: parent.modelData.text
                            color: "white"
                            font.family: "Adwaita Sans"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: parent.modelData.invoke()
                        }
                    }
                }
            }
        }
    }

    // Tombol tutup di pojok kiri atas, seperti macOS
    Glass {
        visible: hover.hovered
        x: -6
        y: -6
        width: 20
        height: 20
        radius: 10
        tint: Qt.rgba(0.25, 0.25, 0.28, 0.85)

        Text {
            anchors.centerIn: parent
            text: "close"
            color: "white"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 13
        }

        MouseArea {
            anchors.fill: parent
            onClicked: card.notification.dismiss()
        }
    }
}
