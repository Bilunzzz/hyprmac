pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Lirik tersinkron untuk lagu yang sedang diputar, dari LRCLIB (lrclib.net).
// Tanpa internet atau lirik tidak ditemukan: `lines` kosong.
Singleton {
    id: root

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string key: player?.trackTitle ? `${player.trackArtist}|${player.trackTitle}` : ""

    property var lines: [] // [{ time: detik, text }]
    property bool tracking: false // posisi lagu hanya diperbarui saat lirik terlihat
    property var cache: ({})

    // Baris yang sedang dinyanyikan
    readonly property int current: {
        const t = (player?.position ?? 0) + 0.25;
        let index = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].time > t)
                break;
            index = i;
        }
        return index;
    }

    function parse(lrc: string): var {
        const out = [];
        for (const line of lrc.split("\n")) {
            const m = line.match(/^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/);
            if (m)
                out.push({ time: parseInt(m[1]) * 60 + parseFloat(m[2]), text: m[3] || "♪" });
        }
        return out;
    }

    function request(url: string, done): void {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            try {
                done(xhr.status === 200 ? JSON.parse(xhr.responseText) : null);
            } catch (e) {
                done(null);
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function fetch(): void {
        lines = [];
        if (!key)
            return;
        if (cache[key]) {
            lines = cache[key];
            return;
        }

        const k = key;
        const artist = encodeURIComponent(player.trackArtist ?? "");
        const title = encodeURIComponent(player.trackTitle ?? "");
        const finish = lrc => {
            const parsed = lrc ? parse(lrc) : [];
            cache[k] = parsed;
            if (k === key)
                lines = parsed;
        };

        // Coba yang persis dulu, lalu pencarian bebas
        request(`https://lrclib.net/api/get?artist_name=${artist}&track_name=${title}&duration=${Math.round(player.length || 0)}`, data => {
            if (data?.syncedLyrics)
                return finish(data.syncedLyrics);
            request(`https://lrclib.net/api/search?q=${artist}%20${title}`, results => {
                finish((results ?? []).find(r => r.syncedLyrics)?.syncedLyrics ?? "");
            });
        });
    }

    onKeyChanged: fetch()
    Component.onCompleted: fetch()

    Timer {
        running: root.tracking && (root.player?.isPlaying ?? false)
        interval: 250
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}
