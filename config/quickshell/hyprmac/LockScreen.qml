import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.UPower

// Tampilan layar kunci ala macOS + liquid glass. Dipakai Lock.qml untuk
// layar kunci sungguhan dan untuk pratinjau (qs ... ipc call lock preview).
//   compact  : wallpaper, jam besar, kartu musik kecil di atas nama pengguna
//   expanded : latar sampul album (blur), sampul besar + pemutar di tengah
//   lyrics   : seperti expanded, sampul bergeser ke kiri, lirik di kanan
Item {
    id: root

    required property var auth // Lock.qml: buffer, state, handleKey()
    property bool unlocking: false

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool hasMedia: player !== null && (player.trackTitle ?? "") !== ""
    readonly property bool hasLyrics: Lyrics.lines.length > 0
    property string mode: "compact"
    readonly property string shownMode: hasMedia ? (mode === "lyrics" && !hasLyrics ? "expanded" : mode) : "compact"
    readonly property bool big: shownMode !== "compact"

    readonly property string home: Quickshell.env("HOME")
    readonly property string user: Quickshell.env("USER") ?? ""

    function formatTime(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    focus: true
    Keys.onPressed: event => root.auth.handleKey(event)

    Component.onDestruction: Lyrics.tracking = false

    // Posisi lagu tidak diperbarui otomatis oleh MPRIS
    Timer {
        running: root.hasMedia && (root.player?.isPlaying ?? false)
        interval: 500
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Muncul turun dari atas; saat terbuka meluncur ke atas memperlihatkan desktop
    property bool shown: false
    Component.onCompleted: {
        Lyrics.tracking = true;
        shown = true;
    }

    Item {
        id: content

        width: parent.width
        height: parent.height
        y: root.unlocking ? -root.height : (root.shown ? 0 : -root.height * 0.06)
        opacity: root.shown ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: root.unlocking ? 520 : 420
                easing.type: root.unlocking ? Easing.InOutCubic : Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        // Dasar pekat (wallpaper bisa belum termuat)
        Rectangle {
            anchors.fill: parent
            color: "#1c1c22"
        }

        // ---------------------------------------------------------- latar
        Image {
            anchors.fill: parent
            source: "file://" + root.home + "/.cache/hyprmac/wallpaper.png"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }

        // Sampul album di-blur sebagai latar saat pemutar diperbesar
        Item {
            anchors.fill: parent
            opacity: root.big ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 450
                    easing.type: Easing.OutCubic
                }
            }

            // Sampul kecil diperbesar lalu di-blur: halus, tanpa pola kotak-kotak
            Image {
                id: artBackground

                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize: Qt.size(96, 96)
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: artBackground
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                blurMultiplier: 1.5
                saturation: 0.15
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.18)
            }
        }

        // Gelap tipis di atas supaya jam terbaca di wallpaper terang
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            height: 360
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.22) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        // ----------------------------------------------------- jam & tanggal
        Text {
            id: date

            anchors.horizontalCenter: parent.horizontalCenter
            y: 58
            text: clock.date.toLocaleDateString(Qt.locale("en_US"), "dddd, MMMM d")
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: "Adwaita Sans"
            font.pixelSize: 21
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: date.bottom
            anchors.topMargin: -6
            transformOrigin: Item.Top
            scale: root.big ? 0.52 : 1
            text: Qt.formatTime(clock.date, "H:mm")
            color: Qt.rgba(1, 1, 1, 0.88)
            font.family: "Adwaita Sans"
            font.pixelSize: 128
            font.weight: Font.DemiBold
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowOpacity: 0.25
                shadowBlur: 0.6
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 380
                    easing.type: Easing.OutCubic
                }
            }
        }

        // ------------------------------------------------ status kanan atas
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: 8
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: UPower.displayDevice?.isLaptopBattery ?? false
                text: Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%"
                color: Qt.rgba(1, 1, 1, 0.9)
                font.family: "Adwaita Sans"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "wifi"
                color: Qt.rgba(1, 1, 1, 0.9)
                font.family: "Material Symbols Rounded"
                font.pixelSize: 16
            }
        }

        // ------------------------------------------------- notifikasi
        Column {
            anchors.right: parent.right
            anchors.rightMargin: 14
            y: 34
            width: 230
            spacing: 8

            Repeater {
                model: [...Notifs.list].reverse().slice(0, 4)

                Glass {
                    id: notif

                    required property var modelData

                    width: parent.width
                    height: 42
                    radius: 13
                    tint: Qt.rgba(0.12, 0.12, 0.14, 0.32)

                    ClippingRectangle {
                        id: notifIcon

                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 24
                        radius: 6
                        color: "transparent"

                        Image {
                            anchors.fill: parent
                            sourceSize: Qt.size(48, 48)
                            source: {
                                const n = notif.modelData;
                                const icon = n.image || n.appIcon || DesktopEntries.heuristicLookup(n.desktopEntry || n.appName)?.icon || "dialog-information";
                                return icon.startsWith("/") || icon.startsWith("file:") || icon.startsWith("image:") ? icon : Quickshell.iconPath(icon, "dialog-information");
                            }
                        }
                    }

                    Column {
                        anchors.left: notifIcon.right
                        anchors.leftMargin: 9
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter

                        Item {
                            width: parent.width
                            height: appName.implicitHeight

                            Text {
                                id: appName

                                anchors.left: parent.left
                                anchors.right: ago.left
                                elide: Text.ElideRight
                                text: notif.modelData.appName
                                color: "white"
                                font.family: "Adwaita Sans"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Text {
                                id: ago

                                anchors.right: parent.right
                                text: Notifs.ago(notif.modelData)
                                color: Qt.rgba(1, 1, 1, 0.55)
                                font.family: "Adwaita Sans"
                                font.pixelSize: 9
                            }
                        }

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: notif.modelData.summary
                            color: Qt.rgba(1, 1, 1, 0.75)
                            font.family: "Adwaita Sans"
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        // ---------------------------------------------------- pemutar musik
        Item {
            id: media

            readonly property real artSize: 250
            readonly property real lyricsWidth: 440
            readonly property real gap: 34
            // Sampul + kartu digeser ke kiri saat lirik tampil
            readonly property real groupX: root.shownMode === "lyrics" ? (root.width - artSize - gap - lyricsWidth) / 2 : (root.width - artSize) / 2
            readonly property real artY: root.height * 0.3

            anchors.fill: parent
            visible: root.hasMedia

            // Sampul besar
            Item {
                id: bigArt

                x: media.groupX
                y: media.artY
                width: media.artSize
                height: media.artSize
                opacity: root.big ? 1 : 0
                scale: root.big ? 1 : 0.85

                Behavior on x {
                    NumberAnimation {
                        duration: 420
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 380
                        easing.type: Easing.OutBack
                    }
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowOpacity: 0.45
                    shadowBlur: 1.0
                    shadowVerticalOffset: 10
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 18
                    color: "#2c2c30"

                    Image {
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(500, 500)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.mode = "compact"
                }
            }

            // Kartu pemutar (ringkas di bawah, atau di bawah sampul besar)
            Glass {
                id: card

                readonly property bool compact: !root.big

                x: root.big ? media.groupX : (root.width - width) / 2
                y: root.big ? media.artY + media.artSize + 16 : root.height - 330
                width: media.artSize
                height: compact ? 104 : 92
                radius: 18
                tint: Qt.rgba(0.14, 0.14, 0.16, 0.32)

                Behavior on x {
                    NumberAnimation {
                        duration: 420
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 420
                        easing.type: Easing.OutCubic
                    }
                }

                // Klik kartu ringkas = perbesar
                MouseArea {
                    anchors.fill: parent
                    enabled: card.compact
                    onClicked: root.mode = "expanded"
                }

                // Judul: dengan sampul kecil (ringkas) atau rata tengah (besar)
                Item {
                    id: header

                    x: 12
                    y: 11
                    width: parent.width - 24
                    height: card.compact ? 38 : 30

                    ClippingRectangle {
                        id: smallArt

                        visible: card.compact
                        width: 38
                        height: 38
                        radius: 8
                        color: "#2c2c30"

                        Image {
                            anchors.fill: parent
                            source: root.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Column {
                        anchors.left: card.compact ? smallArt.right : parent.left
                        anchors.leftMargin: card.compact ? 10 : 0
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            width: parent.width
                            horizontalAlignment: card.compact ? Text.AlignLeft : Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.player?.trackTitle ?? ""
                            color: "white"
                            font.family: "Adwaita Sans"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: card.compact ? Text.AlignLeft : Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.player?.trackArtist ?? ""
                            color: Qt.rgba(1, 1, 1, 0.6)
                            font.family: "Adwaita Sans"
                            font.pixelSize: 11
                        }
                    }
                }

                // Progres
                Item {
                    id: progress

                    x: 12
                    anchors.top: header.bottom
                    anchors.topMargin: 8
                    width: parent.width - 24
                    height: 10

                    Text {
                        id: elapsed

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.formatTime(root.player?.position ?? 0)
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.family: "Adwaita Sans"
                        font.pixelSize: 8
                    }

                    Text {
                        id: remaining

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "-" + root.formatTime((root.player?.length ?? 0) - (root.player?.position ?? 0))
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.family: "Adwaita Sans"
                        font.pixelSize: 8
                    }

                    Rectangle {
                        anchors.left: elapsed.right
                        anchors.leftMargin: 6
                        anchors.right: remaining.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        height: 3
                        radius: 1.5
                        color: Qt.rgba(1, 1, 1, 0.22)

                        Rectangle {
                            width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                            height: parent.height
                            radius: parent.radius
                            color: Qt.rgba(1, 1, 1, 0.85)
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            enabled: root.player?.canSeek ?? false
                            onClicked: event => root.player.position = root.player.length * event.x / width
                        }
                    }
                }

                // Kontrol
                Item {
                    x: 12
                    anchors.top: progress.bottom
                    anchors.topMargin: 6
                    width: parent.width - 24
                    height: 24

                    Row {
                        anchors.centerIn: parent
                        spacing: 22

                        Repeater {
                            model: [
                                { icon: "fast_rewind", run: () => root.player?.previous() },
                                { icon: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow", run: () => root.player?.togglePlaying() },
                                { icon: "fast_forward", run: () => root.player?.next() }
                            ]

                            Text {
                                required property var modelData

                                text: modelData.icon
                                color: controlMouse.pressed ? Qt.rgba(1, 1, 1, 0.6) : "white"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20

                                MouseArea {
                                    id: controlMouse

                                    anchors.fill: parent
                                    anchors.margins: -6
                                    onClicked: parent.modelData.run()
                                }
                            }
                        }
                    }

                    // Tombol lirik
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        height: 18
                        radius: 5
                        visible: root.hasLyrics
                        color: root.shownMode === "lyrics" ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(1, 1, 1, 0.18)

                        Text {
                            anchors.centerIn: parent
                            text: "lyrics"
                            color: root.shownMode === "lyrics" ? "#2c2c30" : "white"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 14
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: root.mode = root.shownMode === "lyrics" ? "expanded" : "lyrics"
                        }
                    }
                }
            }

            // Lirik berjalan
            ListView {
                id: lyrics

                x: media.groupX + media.artSize + media.gap
                y: media.artY + 40
                width: media.lyricsWidth
                height: media.artSize + 70
                opacity: root.shownMode === "lyrics" ? 1 : 0
                visible: opacity > 0
                interactive: false
                clip: true
                spacing: 14
                model: Lyrics.lines
                currentIndex: Math.max(0, Lyrics.current)
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: 40
                highlightMoveDuration: 450

                Behavior on opacity {
                    NumberAnimation {
                        duration: 350
                    }
                }

                delegate: Text {
                    required property var modelData
                    required property int index

                    readonly property int distance: index - Lyrics.current

                    width: lyrics.width
                    wrapMode: Text.Wrap
                    text: modelData.text
                    color: "white"
                    opacity: distance === 0 ? 1 : (distance < 0 ? 0.25 : Math.max(0.12, 0.55 - distance * 0.1))
                    font.family: "Adwaita Sans"
                    font.pixelSize: 21
                    font.weight: Font.Bold

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------- pengguna
        Column {
            id: userBox

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 70
            spacing: 8

            // Foto ~/.face, atau inisial di lingkaran kaca
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 54
                height: 54

                Glass {
                    anchors.fill: parent
                    radius: width / 2
                    tint: Qt.rgba(1, 1, 1, 0.12)
                    visible: face.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: root.user.charAt(0).toUpperCase()
                        color: "white"
                        font.family: "Adwaita Sans"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                    }
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    visible: face.status === Image.Ready

                    Image {
                        id: face

                        anchors.fill: parent
                        source: "file://" + root.home + "/.face"
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(108, 108)
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.user
                color: Qt.rgba(1, 1, 1, 0.95)
                font.family: "Adwaita Sans"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.35)
            }

            // Kolom kata sandi kapsul
            Glass {
                id: field

                anchors.horizontalCenter: parent.horizontalCenter
                width: 170
                height: 28
                radius: 14
                tint: root.auth.state === "failed" ? Qt.rgba(1, 0.27, 0.23, 0.35) : Qt.rgba(1, 1, 1, 0.1)

                transform: Translate {
                    id: shake
                }

                SequentialAnimation {
                    id: shakeAnim

                    loops: 2

                    NumberAnimation { target: shake; property: "x"; to: -9; duration: 50 }
                    NumberAnimation { target: shake; property: "x"; to: 9; duration: 80 }
                    NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
                }

                Connections {
                    target: root.auth

                    function onStateChanged(): void {
                        if (root.auth.state === "failed")
                            shakeAnim.start();
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideLeft
                    text: root.auth.buffer.length > 0 ? "●".repeat(root.auth.buffer.length) : "Masukkan Kata Sandi"
                    color: root.auth.buffer.length > 0 ? "white" : Qt.rgba(1, 1, 1, 0.55)
                    font.family: "Adwaita Sans"
                    font.pixelSize: root.auth.buffer.length > 0 ? 8 : 11
                    font.letterSpacing: root.auth.buffer.length > 0 ? 2 : 0
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ({
                        checking: "Memeriksa…",
                        failed: "Kata sandi salah",
                        locked: "Terlalu banyak percobaan, tunggu sebentar"
                    })[root.auth.state] ?? "Masukkan kata sandi untuk membuka"
                color: root.auth.state === "failed" || root.auth.state === "locked" ? "#ff8a80" : Qt.rgba(1, 1, 1, 0.7)
                font.family: "Adwaita Sans"
                font.pixelSize: 10
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.35)
            }
        }
    }
}
