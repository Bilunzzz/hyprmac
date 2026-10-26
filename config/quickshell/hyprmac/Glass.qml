import QtQuick

// Permukaan "liquid glass": warna dasar tipis, kilau dari atas, dan tepi
// yang terang di atas lalu meredup. Blur di belakangnya dari Hyprland
// (layer rule "macshell-*" di hypr/lua/shell.lua).
Item {
    id: root

    property real radius: 20
    property color tint: Qt.rgba(0.10, 0.10, 0.12, 0.30)
    property real sheen: 0.10

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tint
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.sheen * 1.6) }
            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, root.sheen * 0.3) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, root.sheen * 0.7) }
        }
    }

    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const r = Math.min(root.radius, width / 2, height / 2);
            const edge = ctx.createLinearGradient(0, 0, 0, height);
            edge.addColorStop(0, "rgba(255,255,255,0.70)");
            edge.addColorStop(0.3, "rgba(255,255,255,0.20)");
            edge.addColorStop(0.75, "rgba(255,255,255,0.10)");
            edge.addColorStop(1, "rgba(255,255,255,0.32)");
            ctx.strokeStyle = edge;
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.roundedRect(0.5, 0.5, width - 1, height - 1, r, r);
            ctx.stroke();
        }
    }
}
