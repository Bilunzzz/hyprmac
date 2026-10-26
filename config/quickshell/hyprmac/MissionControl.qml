import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

// Mission Control ala macOS (SUPER + `):
//   atas   : Spaces bar, thumbnail tiap desktop + tombol "+"
//   tengah : jendela desktop aktif disusun rapi, beranimasi dari posisi aslinya
// Klik jendela = fokus, klik desktop = pindah, seret jendela ke desktop = pindahkan.
PanelWindow {
    id: root

    readonly property bool shown: Globals.missionOpen
    property bool ready: false
    property real progress: shown && ready ? 1 : 0

    property var clients: []
    property var monitor: ({ x: 0, y: 0, width: 1920, height: 1080, scale: 1 })
    property int activeWs: 1
    property list<int> workspaces: []
    property string wallpaper: ""
    property int dropTarget: 0 // id desktop di bawah jendela yang diseret

    readonly property real screenW: monitor.width / monitor.scale
    readonly property real screenH: monitor.height / monitor.scale
    readonly property real thumbW: 176
    readonly property real thumbH: thumbW * screenH / screenW
    readonly property real thumbScale: thumbW / screenW
    readonly property var items: layout(clients.filter(c => c.workspace.id === activeWs), {
        x: 70,
        y: thumbH + 90,
        w: width - 140,
        h: height - thumbH - 150
    })

    function close(): void {
        Globals.missionOpen = false;
    }

    function addressOf(c): string {
        return Globals.windowSelector(c.address);
    }

    function toplevelOf(c) {
        const addr = c.address.replace(/^0x/, "");
        return Hyprland.toplevels.values.find(h => h.address.replace(/^0x/, "") === addr)?.wayland ?? null;
    }

    // Susun jendela dalam grid yang memakai ruang paling banyak (gaya Exposé)
    function layout(wins, area) {
        const n = wins.length;
        if (n === 0)
            return [];
        const gap = 40;
        const label = 28;
        const sorted = [...wins].sort((a, b) => (a.at[1] - b.at[1]) || (a.at[0] - b.at[0]));

        let best = null;
        for (let cols = 1; cols <= n; cols++) {
            const rows = Math.ceil(n / cols);
            const cw = (area.w - gap * (cols - 1)) / cols;
            const ch = (area.h - (gap + label) * rows) / rows;
            const scales = sorted.map(w => Math.min(cw / w.size[0], ch / w.size[1], 0.8));
            const total = sorted.reduce((sum, w, i) => sum + w.size[0] * w.size[1] * scales[i] * scales[i], 0);
            if (!best || total > best.total)
                best = { cols: cols, rows: rows, ch: ch, scales: scales, total: total };
        }

        const out = [];
        const blockH = best.rows * (best.ch + label) + gap * (best.rows - 1);
        for (let r = 0; r < best.rows; r++) {
            const row = sorted.slice(r * best.cols, (r + 1) * best.cols);
            const sc = best.scales.slice(r * best.cols, (r + 1) * best.cols);
            const rowW = row.reduce((sum, w, i) => sum + w.size[0] * sc[i], 0) + gap * (row.length - 1);
            const cy = area.y + (area.h - blockH) / 2 + r * (best.ch + label + gap) + best.ch / 2;
            let x = area.x + (area.w - rowW) / 2;
            row.forEach((w, i) => {
                const tw = w.size[0] * sc[i];
                const th = w.size[1] * sc[i];
                out.push({
                    client: w,
                    rx: w.at[0] - root.monitor.x,
                    ry: w.at[1] - root.monitor.y,
                    rw: w.size[0],
                    rh: w.size[1],
                    tx: x,
                    ty: cy - th / 2,
                    tw: tw,
                    th: th
                });
                x += tw + gap;
            });
        }
        return out;
    }

    function refresh(): void {
        infoProc.running = true;
    }

    onShownChanged: {
        if (shown) {
            ready = false;
            refresh();
            focusItem.forceActiveFocus();
        }
    }

    Behavior on progress {
        NumberAnimation {
            duration: 330
            easing.type: Easing.OutCubic
        }
    }

    // Data jendela, monitor, workspace, dan gambar wallpaper (dari wallpaper.sh)
    Process {
        id: infoProc

        command: ["sh", "-c", "hyprctl -j clients; echo '@@'; hyprctl -j monitors; echo '@@'; hyprctl -j workspaces; echo '@@'; echo \"$HOME/.cache/hyprmac/wallpaper.png\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("@@");
                const mon = JSON.parse(parts[1]).find(m => m.focused) ?? JSON.parse(parts[1])[0];
                root.monitor = mon;
                root.activeWs = mon.activeWorkspace.id;
                root.clients = JSON.parse(parts[0]).filter(c => c.mapped && !c.hidden && c.workspace.id > 0 && c.monitor === mon.id);
                const ids = JSON.parse(parts[2]).filter(w => w.id > 0 && w.monitorID === mon.id).map(w => w.id);
                if (!ids.includes(root.activeWs))
                    ids.push(root.activeWs);
                root.workspaces = ids.sort((a, b) => a - b);
                root.wallpaper = "file://" + parts[3].trim();
                root.ready = true;
            }
        }
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
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
    visible: shown || progress > 0.001

    WlrLayershell.namespace: "macshell-mission"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        id: focusItem

        focus: true
        Keys.onEscapePressed: root.close()
    }

    // Latar gelap di atas blur; klik kosong menutup
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.02, 0.05, 0.45)
        opacity: root.progress

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // ---------- Spaces bar ----------
    Row {
        id: spaces

        anchors.horizontalCenter: parent.horizontalCenter
        y: -root.thumbH - 40 + (root.thumbH + 40 + 38) * root.progress
        spacing: 22
        opacity: root.progress

        Repeater {
            model: root.workspaces

            Column {
                id: space

                required property int modelData
                readonly property int wsId: modelData
                readonly property bool active: wsId === root.activeWs

                spacing: 7

                ClippingRectangle {
                    width: root.thumbW
                    height: root.thumbH
                    radius: 9
                    color: "#1c1c1e"
                    border.width: space.active || root.dropTarget === space.wsId ? 2 : (spaceMouse.containsMouse ? 1 : 0)
                    border.color: root.dropTarget === space.wsId ? "#0a84ff" : (space.active ? "white" : Qt.rgba(1, 1, 1, 0.5))

                    Image {
                        anchors.fill: parent
                        source: root.wallpaper
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(352, 200)
                    }

                    // Jendela mini
                    Repeater {
                        model: root.clients.filter(c => c.workspace.id === space.wsId)

                        ScreencopyView {
                            required property var modelData

                            x: (modelData.at[0] - root.monitor.x) * root.thumbScale
                            y: (modelData.at[1] - root.monitor.y) * root.thumbScale
                            width: modelData.size[0] * root.thumbScale
                            height: modelData.size[1] * root.thumbScale
                            captureSource: root.shown ? root.toplevelOf(modelData) : null
                            live: false
                        }
                    }

                    MouseArea {
                        id: spaceMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            Globals.hyprDispatch(`hl.dsp.focus({ workspace = ${space.wsId} })`);
                            root.close();
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: `Desktop ${space.wsId}`
                    color: space.active ? "white" : Qt.rgba(1, 1, 1, 0.7)
                    font.family: "Adwaita Sans"
                    font.pixelSize: 12
                    font.weight: space.active ? Font.DemiBold : Font.Normal
                }
            }
        }

        // Desktop baru
        Glass {
            width: 44
            height: root.thumbH
            radius: 9
            tint: Qt.rgba(1, 1, 1, plusMouse.containsMouse ? 0.14 : 0.06)

            Text {
                anchors.centerIn: parent
                text: "add"
                color: "white"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 26
            }

            MouseArea {
                id: plusMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    Globals.hyprDispatch(`hl.dsp.focus({ workspace = "empty" })`);
                    root.close();
                }
            }
        }
    }

    // ---------- Jendela desktop aktif ----------
    Repeater {
        model: root.items

        Item {
            id: win

            required property var modelData
            readonly property real p: root.progress
            property bool dragging: false
            property real dragX: 0
            property real dragY: 0

            x: modelData.rx + (modelData.tx - modelData.rx) * p + dragX
            y: modelData.ry + (modelData.ty - modelData.ry) * p + dragY
            width: modelData.rw + (modelData.tw - modelData.rw) * p
            height: modelData.rh + (modelData.th - modelData.rh) * p
            opacity: dragging ? 0.8 : 1
            z: dragging ? 10 : 1

            ClippingRectangle {
                anchors.fill: parent
                radius: 10
                color: "#1c1c1e"
                border.width: winMouse.containsMouse && !win.dragging ? 3 : 0
                border.color: "#0a84ff"

                ScreencopyView {
                    anchors.fill: parent
                    captureSource: root.shown ? root.toplevelOf(win.modelData.client) : null
                    live: true
                }
            }

            // Ikon aplikasi di pojok bawah
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.bottom
                width: 44
                height: 44
                opacity: root.progress
                source: Quickshell.iconPath(DesktopEntries.heuristicLookup(win.modelData.client.class)?.icon ?? win.modelData.client.class, "application-x-executable")
                sourceSize: Qt.size(88, 88)
            }

            // Judul saat diarahkan
            Glass {
                visible: winMouse.containsMouse && !win.dragging
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 26
                width: Math.min(titleText.implicitWidth + 24, Math.max(parent.width, 160))
                height: 24
                radius: 12
                tint: Qt.rgba(0.12, 0.12, 0.14, 0.75)

                Text {
                    id: titleText

                    anchors.centerIn: parent
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: win.modelData.client.title || win.modelData.client.class
                    color: "white"
                    font.family: "Adwaita Sans"
                    font.pixelSize: 12
                }
            }

            MouseArea {
                id: winMouse

                property point start

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                onPressed: event => start = Qt.point(event.x, event.y)
                onPositionChanged: event => {
                    if (!pressed)
                        return;
                    const dx = event.x - start.x;
                    const dy = event.y - start.y;
                    if (!win.dragging && Math.hypot(dx, dy) > 8)
                        win.dragging = true;
                    if (win.dragging) {
                        win.dragX += dx;
                        win.dragY += dy;
                        const pos = mapToItem(spaces, event.x, event.y);
                        const space = spaces.childAt(pos.x, pos.y);
                        root.dropTarget = space?.wsId ?? 0;
                    }
                }
                onReleased: event => {
                    const addr = root.addressOf(win.modelData.client);
                    if (win.dragging) {
                        if (root.dropTarget > 0 && root.dropTarget !== root.activeWs) {
                            Globals.hyprDispatch(`hl.dsp.window.move({ workspace = ${root.dropTarget}, window = "${addr}", follow = false })`);
                            refreshTimer.restart();
                        }
                        win.dragging = false;
                        win.dragX = 0;
                        win.dragY = 0;
                        root.dropTarget = 0;
                        return;
                    }
                    if (event.button === Qt.MiddleButton) {
                        Globals.hyprDispatch(`hl.dsp.window.close({ window = "${addr}" })`);
                        refreshTimer.restart();
                        return;
                    }
                    Globals.hyprDispatch(`hl.dsp.focus({ window = "${addr}" })`);
                    root.close();
                }
            }
        }
    }

    // Tunggu Hyprland selesai memindahkan/menutup jendela sebelum menyusun ulang
    Timer {
        id: refreshTimer
        interval: 150
        onTriggered: root.refresh()
    }

    Text {
        visible: root.items.length === 0 && root.ready
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.thumbH / 2
        opacity: root.progress
        text: "Tidak ada jendela di desktop ini"
        color: Qt.rgba(1, 1, 1, 0.55)
        font.family: "Adwaita Sans"
        font.pixelSize: 15
    }
}
