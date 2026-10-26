import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Dock ala macOS: mengambang di atas jendela, tersembunyi sampai kursor
// menyentuh tepi bawah layar, ikon membesar hanya saat kursor tepat di dock,
// titik untuk aplikasi yang berjalan, ikon memantul saat dibuka.
PanelWindow {
    id: root

    property real iconSize: 50
    property real maxZoom: 1.8
    property real influence: 160 // jarak (px) dari kursor yang ikut membesar
    property real padding: 7
    property bool autoHide: true

    property bool zooming: false // kursor tepat di atas dock
    property real pointerX: -9999 // posisi kursor dalam koordinat `row`
    property bool shownByPointer: false
    readonly property bool revealed: !autoHide || shownByPointer || Globals.launchpadOpen

    // Ikon tersemat + jendela yang berjalan, digabung per aplikasi
    readonly property var apps: {
        const out = [{ key: "__launchpad", launchpad: true, name: "Launchpad", icon: "view-app-grid", toplevels: [] }];
        const extra = [];

        const make = (id, pinned) => {
            const entry = DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id);
            const match = [id, entry?.id, entry?.startupClass].filter(s => s).map(s => s.toLowerCase());
            return { key: id, entry: entry, name: entry?.name ?? id, icon: entry?.icon ?? id, pinned: pinned, match: match, toplevels: [] };
        };

        // Aplikasi tersemat yang belum terpasang dilewati
        for (const id of Globals.pinned) {
            const app = make(id, true);
            if (app.entry)
                out.push(app);
        }

        for (const t of ToplevelManager.toplevels.values) {
            if (!t.appId)
                continue;
            const lc = t.appId.toLowerCase();
            let app = out.find(a => a.match?.includes(lc)) ?? extra.find(a => a.match.includes(lc));
            if (!app) {
                app = make(t.appId, false);
                extra.push(app);
            }
            app.toplevels.push(t);
        }

        if (extra.length > 0)
            out.push({ key: "__separator", separator: true, toplevels: [] }, ...extra);
        return out;
    }

    function activate(app): void {
        if (app.launchpad) {
            Globals.launchpadOpen = !Globals.launchpadOpen;
            return;
        }
        Globals.launchpadOpen = false;

        const tops = app.toplevels;
        if (tops.length === 0) {
            if (app.entry)
                app.entry.execute();
            else
                Quickshell.execDetached([app.key]);
            return;
        }

        // Jendela yang di-minimize (tombol kuning) dikembalikan ke workspace aktif
        const hypr = tops.map(t => Hyprland.toplevels.values.find(h => h.wayland === t)).filter(h => h);
        const hidden = hypr.find(h => (h.workspace?.name ?? "").startsWith("special:minimized"));
        if (hidden) {
            const ws = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1;
            const sel = Globals.windowSelector(hidden.address);
            Globals.hyprDispatch(`hl.dsp.window.move({ workspace = ${ws}, window = "${sel}" })`);
            Globals.hyprDispatch(`hl.dsp.focus({ window = "${sel}" })`);
            return;
        }

        // Klik berulang berpindah ke jendela berikutnya dari aplikasi yang sama
        const current = tops.findIndex(t => t.activated);
        tops[(current + 1) % tops.length].activate();
    }

    function updatePointer(): void {
        if (!hover.hovered) {
            zooming = false;
            pointerX = -9999;
            if (autoHide)
                hideTimer.restart();
            return;
        }

        shownByPointer = true;
        hideTimer.stop();

        // Koordinat jendela, bukan koordinat hitbox: hitbox sendiri bergeser saat
        // dock muncul/zoom, dan posisi relatifnya jadi basi (zoom berkedut).
        const px = hover.point.scenePosition.x;
        const py = hover.point.scenePosition.y;
        const onBody = py >= body.y && py <= body.y + body.height;
        // Setelah membesar, ikon yang tinggi tetap dihitung bagian dari dock
        const onIcons = py >= row.y + row.childrenRect.y && py <= body.y + body.height;
        zooming = onBody || (zooming && onIcons);
        // Diukur terhadap tata letak dasar (tanpa zoom) yang selalu di tengah layar,
        // supaya ikon yang membesar tidak menggeser titik acuan
        pointerX = zooming ? px - (width - baseRowWidth) / 2 : -9999;
    }

    // Titik tengah tiap ikon sebelum zoom, dan lebar total barisnya
    readonly property real separatorWidth: 11
    readonly property list<real> baseCenters: {
        const centers = [];
        let x = 0;
        for (const app of apps) {
            const w = app.separator ? separatorWidth : iconSize;
            centers.push(x + w / 2);
            x += w + row.spacing;
        }
        return centers;
    }
    readonly property real baseRowWidth: apps.reduce((sum, a) => sum + (a.separator ? separatorWidth : iconSize), 0) + row.spacing * Math.max(0, apps.length - 1)

    anchors.bottom: true
    implicitWidth: screen.width
    implicitHeight: iconSize * maxZoom + 60
    exclusiveZone: 0 // mengambang di atas jendela, jendela tetap penuh
    color: "transparent"

    WlrLayershell.namespace: "macshell-dock"
    WlrLayershell.layer: WlrLayer.Top

    // Pakai angka eksplisit, bukan `item: hitbox`: mask berbasis item tidak ikut
    // berubah saat hitbox membesar, sehingga kursor tembus ke jendela di belakang
    // dan dock langsung bersembunyi lagi.
    mask: Region {
        x: hitbox.x
        y: hitbox.y
        width: hitbox.width
        height: hitbox.height
    }

    Timer {
        id: hideTimer
        interval: 350
        onTriggered: root.shownByPointer = false
    }

    // Area yang menerima kursor:
    //   tersembunyi -> garis tipis di tepi bawah layar (selebar dock)
    //   tampil      -> badan dock sampai tepi bawah, plus ikon yang membesar
    Item {
        id: hitbox

        x: body.x
        width: body.width
        y: root.revealed ? row.y : root.height - 2
        height: root.height - y
    }

    // Di tingkat jendela (induk semua ikon), bukan di hitbox: kalau di hitbox,
    // MouseArea ikon "mencuri" hover sehingga dock mengira kursor pergi.
    // Jendela hanya menerima kursor di dalam mask, jadi cakupannya sama.
    HoverHandler {
        id: hover

        onHoveredChanged: root.updatePointer()
        onPointChanged: root.updatePointer()
    }

    Glass {
        id: body

        anchors.horizontalCenter: parent.horizontalCenter
        width: row.width + root.padding * 2
        height: root.iconSize + root.padding * 2
        y: root.height - height - 6 + (root.revealed ? 0 : height + 12)
        radius: 22

        Behavior on y {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        id: row

        anchors.horizontalCenter: body.horizontalCenter
        anchors.bottom: body.bottom
        anchors.bottomMargin: root.padding
        height: root.iconSize * root.maxZoom
        spacing: 5

        Repeater {
            model: ScriptModel {
                values: root.apps
                objectProp: "key"
            }

            DockItem {
                dock: root
            }
        }
    }
}
