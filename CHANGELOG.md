# Changelog

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/),
versi mengikuti [Semantic Versioning](https://semver.org/lang/id/).

## [Belum dirilis]

### Ditambahkan

- Layar kunci baru di Quickshell (session lock + PAM), gaya macOS liquid glass:
  jam & tanggal, notifikasi, kartu musik yang bisa diperbesar (latar sampul
  album di-blur), lirik tersinkron dari LRCLIB, dan animasi meluncur ke atas
  saat terbuka. hyprlock tetap dipakai sebagai cadangan.
- Mode pratinjau layar kunci: `qs -c hyprmac ipc call lock preview`.

### Diperbaiki

- Screenshot di clipboard selalu PNG, supaya bisa di-paste di Chrome, Discord, dll.
- Panel layar penuh tidak lagi memblokir klik kalau animasi tutupnya tersendat.

## [1.0] - 2026-10-26

Rilis pertama.

### Ditambahkan

- Menu bar ala macOS (waybar): menu Apple, nama aplikasi aktif, baterai, Wi-Fi,
  Spotlight, Control Center, tanggal & jam.
- Dock (Quickshell): mengambang, sembunyi otomatis, zoom mengikuti kursor,
  ikon memantul, titik aplikasi berjalan, mengembalikan jendela yang di-minimize.
- Launchpad dengan halaman yang digeser ke samping dan pencarian.
- Mission Control dengan pratinjau jendela langsung, Spaces bar, seret jendela
  antar desktop, dan gesture 4 jari.
- Dynamic Island: musik, OSD volume/kecerahan, hitung mundur screenshot.
- Control Center dan Notification Center (kalender + riwayat), notifikasi
  bergaya liquid glass.
- Menu Apple, dialog daya dengan hitung mundur, jendela Tentang Komputer Ini.
- Toolbar screenshot ala ⌘⇧5 (Langsung / Tunda).
- Tombol jendela merah/kuning/hijau (hyprbars), layar kunci ala macOS.
- `install.sh` (dengan backup otomatis) dan `uninstall.sh`.

[1.0]: https://github.com/Bilunzzz/hyprmac/releases/tag/v1.0
