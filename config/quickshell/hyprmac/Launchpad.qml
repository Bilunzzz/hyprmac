import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Launchpad: grid aplikasi layar penuh, halaman digeser ke samping
// (scroll, swipe touchpad, drag, panah kiri/kanan, atau klik titik halaman).
PanelWindow {
    id: root

    readonly property int columns: 7
    readonly property int rows: 5
    readonly property int perPage: columns * rows
    readonly property bool shown: Globals.launchpadOpen

    property string query: ""
    property real progress: shown ? 1 : 0

    readonly property var apps: [...DesktopEntries.applications.values].filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property var filtered: {
        const q = query.trim().toLowerCase();
        if (!q)
            return apps;
        return apps.filter(a => [a.name, a.genericName, ...(a.keywords ?? [])].join(" ").toLowerCase().includes(q));
    }
    readonly property int pageCount: Math.max(1, Math.ceil(filtered.length / perPage))

    function close(): void {
        Globals.launchpadOpen = false;
    }

    function launch(entry): void {
        entry.execute();
        close();
    }

    onShownChanged: {
        if (shown) {
            search.text = "";
            pages.currentIndex = 0;
            pages.positionViewAtBeginning();
            search.forceActiveFocus();
        }
    }

    Behavior on progress {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: progress > 0.001
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore

    // Tangkap klik hanya saat terbuka, supaya panel yang animasi tutupnya
    // tersendat (mis. GPU sibuk) tidak memblokir seluruh layar
    mask: Region {
        width: root.shown ? root.width : 0
        height: root.shown ? root.height : 0
    }
    color: "transparent"

    WlrLayershell.namespace: "macshell-launchpad"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Latar gelap tipis di atas blur
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.04, 0.04, 0.07, 0.38)
        opacity: root.progress
    }

    // Klik di area kosong menutup Launchpad
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        id: content

        anchors.fill: parent
        opacity: root.progress
        scale: 1.1 - 0.1 * root.progress

        Glass {
            id: searchBox

            anchors.horizontalCenter: parent.horizontalCenter
            y: 56
            width: 280
            height: 34
            radius: 17
            tint: Qt.rgba(1, 1, 1, 0.06)

            Text {
                id: searchIcon

                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                color: Qt.rgba(1, 1, 1, 0.7)
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
            }

            TextInput {
                id: search

                anchors.left: searchIcon.right
                anchors.leftMargin: 6
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
                font.family: "Adwaita Sans"
                font.pixelSize: 14
                selectByMouse: true
                clip: true
                onTextChanged: {
                    root.query = text;
                    pages.currentIndex = 0;
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.close();
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.filtered.length > 0)
                            root.launch(root.filtered[pages.currentIndex * root.perPage] ?? root.filtered[0]);
                    } else if ((event.key === Qt.Key_Right && text === "") || event.key === Qt.Key_PageDown) {
                        pages.incrementCurrentIndex();
                    } else if ((event.key === Qt.Key_Left && text === "") || event.key === Qt.Key_PageUp) {
                        pages.decrementCurrentIndex();
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                Text {
                    visible: !search.text
                    text: "Search"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font: search.font
                }
            }
        }

        ListView {
            id: pages

            anchors.top: searchBox.bottom
            anchors.topMargin: 36
            anchors.bottom: dots.top
            anchors.bottomMargin: 24
            anchors.left: parent.left
            anchors.right: parent.right

            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 380
            boundsBehavior: Flickable.DragOverBounds
            flickDeceleration: 4000
            model: root.pageCount

            // Scroll / swipe touchpad: satu gerakan = satu halaman
            WheelHandler {
                id: wheel

                property real accumulated: 0
                property bool cooling: false

                onWheel: event => {
                    if (cooling)
                        return;
                    const dx = event.pixelDelta.x || event.angleDelta.x;
                    const dy = event.pixelDelta.y || event.angleDelta.y;
                    accumulated += Math.abs(dx) > Math.abs(dy) ? dx : dy;
                    if (Math.abs(accumulated) >= 100) {
                        if (accumulated < 0)
                            pages.incrementCurrentIndex();
                        else
                            pages.decrementCurrentIndex();
                        accumulated = 0;
                        cooling = true;
                        cooldown.restart();
                    }
                    resetTimer.restart();
                }
            }

            Timer {
                id: cooldown
                interval: 420
                onTriggered: wheel.cooling = false
            }

            Timer {
                id: resetTimer
                interval: 200
                onTriggered: wheel.accumulated = 0
            }

            delegate: Item {
                id: page

                required property int index

                width: pages.width
                height: pages.height

                Grid {
                    anchors.centerIn: parent
                    columns: root.columns
                    rowSpacing: 18

                    Repeater {
                        model: root.filtered.slice(page.index * root.perPage, (page.index + 1) * root.perPage)

                        Item {
                            id: tile

                            required property var modelData

                            width: Math.min(160, pages.width / (root.columns + 1))
                            height: 118

                            Image {
                                id: tileIcon

                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 76
                                height: 76
                                source: Quickshell.iconPath(tile.modelData.icon, "application-x-executable")
                                sourceSize: Qt.size(152, 152)
                                smooth: true
                                mipmap: true
                                scale: tileMouse.pressed ? 0.88 : (tileMouse.containsMouse ? 1.06 : 1)

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }
                            }

                            Text {
                                anchors.top: tileIcon.bottom
                                anchors.topMargin: 8
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: tile.modelData.name
                                color: "white"
                                font.family: "Adwaita Sans"
                                font.pixelSize: 13
                                style: Text.Raised
                                styleColor: Qt.rgba(0, 0, 0, 0.35)
                            }

                            MouseArea {
                                id: tileMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.launch(tile.modelData)
                            }
                        }
                    }
                }
            }
        }

        // Titik halaman
        Row {
            id: dots

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 110
            spacing: 10

            Repeater {
                model: root.pageCount

                Rectangle {
                    required property int index

                    width: 8
                    height: 8
                    radius: 4
                    color: index === pages.currentIndex ? "white" : Qt.rgba(1, 1, 1, 0.35)

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: pages.currentIndex = parent.index
                    }
                }
            }
        }
    }
}
