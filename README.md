<div align="center">

# hyprmac

**Hyprland yang terasa seperti macOS**: menu bar, dock dengan efek zoom, Launchpad,
Mission Control, Dynamic Island, Control Center, dan notifikasi *liquid glass*.

![versi](https://img.shields.io/badge/versi-1.0-0a84ff)
![Hyprland](https://img.shields.io/badge/Hyprland-0.56%2B-58e1ff)
![Arch Linux](https://img.shields.io/badge/Arch%20Linux-i%20use%20arch%20btw-1793d1)
![lisensi](https://img.shields.io/badge/lisensi-MIT-green)

</div>

---

## Daftar isi

- [Fitur](#fitur)
- [Kebutuhan](#kebutuhan)
- [Instalasi](#instalasi)
- [Pintasan keyboard](#pintasan-keyboard)
- [Kustomisasi](#kustomisasi)
- [Update](#update)
- [Uninstall](#uninstall)
- [Pemecahan masalah](#pemecahan-masalah)
- [Struktur repo](#struktur-repo)
- [Kredit](#kredit)

---

## Fitur

| | |
|---|---|
| **Menu bar** | Logo Apple dengan menu (Tentang Komputer Ini, Tidurkan, Mulai Ulang…, Matikan…, Kunci Layar, Log Out…), nama aplikasi aktif, baterai, Wi-Fi, Spotlight, Control Center, tanggal & jam. |
| **Dock** | Mengambang di atas jendela dan tersembunyi otomatis. Ikon membesar mengikuti kursor (*magnification*), memantul saat aplikasi dibuka, dan punya titik untuk aplikasi yang berjalan. |
| **Launchpad** | Grid semua aplikasi layar penuh dengan blur. Halaman digeser ke samping (scroll, swipe touchpad, drag, atau panah), dan ada kotak pencarian. |
| **Mission Control** | Semua jendela desktop aktif tampil sebagai pratinjau langsung, beranimasi dari posisi aslinya. Spaces bar di atas untuk pindah desktop; seret jendela ke desktop lain untuk memindahkannya. |
| **Dynamic Island** | Pil hitam di tengah menu bar: sampul album dan gelombang suara saat musik diputar, OSD volume dan kecerahan, hitung mundur screenshot. Arahkan kursor untuk pemutar musik lengkap. |
| **Control Center** | Wi-Fi, Bluetooth, Fokus (Jangan Ganggu), slider layar dan suara, serta pemutar musik. |
| **Notification Center** | Widget kalender dan riwayat notifikasi, meluncur dari kanan. Notifikasi baru tampil sebagai kartu kaca. |
| **Jendela** | Tombol merah / kuning / hijau (plugin hyprbars), sudut bulat, bayangan lembut, dan animasi membuka-menutup. |
| **Spotlight** | Pencarian aplikasi (rofi) di `SUPER + SPACE`. |
| **Screenshot ala ⌘⇧5** | Toolbar melayang: Seluruh Layar / Jendela / Area, **Langsung** atau **Tunda** (5/10/20 detik), simpan ke folder, papan klip, atau editor. |
| **Dialog daya** | Konfirmasi Matikan / Mulai Ulang / Log Out dengan hitung mundur 60 detik, seperti macOS. |
| **Layar kunci** | Jam besar, foto profil, dan kolom kata sandi kaca (hyprlock). |
| **Tentang Komputer Ini** | Logo distro, model laptop, chip, memori, grafis, dan sistem. |

> Bahasa antarmuka: Indonesia.

## Kebutuhan

- **Arch Linux** (atau turunannya: EndeavourOS, CachyOS, dll.)
- **Hyprland 0.56 atau lebih baru.** hyprmac memakai config Lua yang baru ada sejak versi ini. Cek dengan `Hyprland --version`.
- AUR helper seperti [`yay`](https://github.com/Jguer/yay) atau [`paru`](https://github.com/Morganamilo/paru), untuk tema WhiteSur dan kursor Bibata. Tanpa AUR helper, paket AUR dipasang manual.
- Laptop atau PC dengan GPU yang sanggup blur. Intel, AMD, dan NVIDIA semuanya bisa.

<details>
<summary><b>Daftar paket yang dipasang</b></summary>

**Repo resmi (pacman)**

```
hyprland hyprlock hypridle hyprpicker hyprpaper xdg-desktop-portal-hyprland xdg-user-dirs
quickshell waybar rofi
kitty nautilus pavucontrol nwg-look fastfetch swappy
grim slurp wl-clipboard cliphist brightnessctl playerctl jq imagemagick ffmpeg libnotify
polkit-gnome networkmanager bluez bluez-utils wireplumber python
adwaita-fonts ttf-jetbrains-mono-nerd ttf-material-symbols-variable otf-font-awesome
git cmake meson cpio pkgconf gcc
```

**AUR**

```
whitesur-gtk-theme-git whitesur-icon-theme-git bibata-cursor-theme-bin
mpvpaper   # opsional, hanya untuk wallpaper video
```

</details>

## Instalasi

### 1. Pasang Hyprland dan login sekali

Kalau Hyprland belum terpasang:

```bash
sudo pacman -S hyprland
```

Logout, pilih sesi **Hyprland** di layar login (SDDM/GDM/greetd), lalu login.
Plugin title bar (hyprbars) hanya bisa dibangun dari dalam sesi Hyprland.

> Belum punya display manager? Jalankan `Hyprland` dari TTY setelah login.

### 2. Clone repo

```bash
git clone https://github.com/Bilunzzz/hyprmac.git ~/hyprmac
cd ~/hyprmac
```

### 3. Jalankan installer

```bash
./install.sh
```

Installer akan:

1. Memasang semua paket (repo resmi + AUR).
2. **Membackup** config lama (`~/.config/hypr`, `~/.config/waybar`, …) ke `~/.config/hyprmac-backup/<waktu>/`.
3. Menyalin config hyprmac ke `~/.config/`.
4. Menyalin wallpaper ke `~/Pictures/Wallpapers/`.
5. Menerapkan tema GTK WhiteSur, ikon, kursor Bibata, dan font.
6. Menawarkan untuk mengaktifkan NetworkManager dan Bluetooth.
7. Membangun plugin **hyprbars** dengan `hyprpm` (butuh beberapa menit, dan `sudo` diminta sekali).

Opsi lain:

| Perintah | Kegunaan |
|---|---|
| `./install.sh --no-packages` | Lewati pemasangan paket, hanya pasang config |
| `./install.sh --yes` | Jawab "ya" untuk semua pertanyaan |
| `./install.sh --link` | Symlink config ke repo (untuk yang ingin mengubah dan meng-commit) |

### 4. Terapkan

```bash
hyprctl reload && ~/.config/hypr/scripts/restart-shell.sh
```

Atau cukup logout lalu login lagi. Selesai! 🎉

### 5. (Opsional) Foto profil di layar kunci

Simpan gambar persegi sebagai `~/.face`.

## Pintasan keyboard

`SUPER` = tombol Windows / ⌘.

**Ala macOS**

| Pintasan | Aksi |
|---|---|
| `SUPER + SPACE` | Spotlight |
| `SUPER + A` | Launchpad |
| `` SUPER + ` `` | Mission Control |
| Touchpad 4 jari ↑ / ↓ | Buka / tutup Mission Control |
| `SUPER + N` | Notification Center |
| `Print` / `SUPER + Print` | Toolbar screenshot (⌘⇧5) |
| `SUPER + ALT + F` | Screenshot seluruh layar (langsung) |
| `SUPER + ALT + S` | Screenshot area (langsung) |
| `SUPER + CTRL + Q` | Dialog daya (Mulai Ulang / Tidur / Matikan) |
| `SUPER + CTRL + L` | Kunci layar |
| `SUPER + V` | Riwayat clipboard |

**Aplikasi & jendela**

| Pintasan | Aksi |
|---|---|
| `SUPER + RETURN` | Terminal (kitty) |
| `SUPER + B` | Browser (firefox) |
| `SUPER + E` | File (Nautilus) |
| `SUPER + Q` | Tutup jendela |
| `SUPER + SHIFT + Q` | Paksa tutup (kill) |
| `SUPER + F` / `SUPER + M` | Fullscreen / maksimalkan |
| `SUPER + T` | Floating on/off |
| `SUPER + SHIFT + T` | Floating on/off untuk semua jendela di workspace |
| `SUPER + G` | Grup jendela |
| `SUPER + ←↑→↓` | Pindah fokus |
| `SUPER + ALT + ←↑→↓` | Tukar posisi jendela |
| `SUPER + SHIFT + ←↑→↓` | Ubah ukuran |
| `SUPER + klik kiri / kanan` (seret) | Pindah / ubah ukuran jendela |
| `ALT + Tab` | Ganti jendela |

**Workspace**

| Pintasan | Aksi |
|---|---|
| `SUPER + 1…0` | Ke workspace 1–10 |
| `SUPER + SHIFT + 1…0` | Pindahkan jendela ke workspace |
| `SUPER + CTRL + 1…0` | Pindahkan semua jendela ke workspace |
| `SUPER + Tab` / `SUPER + SHIFT + Tab` | Workspace berikut / sebelumnya |
| `SUPER + CTRL + ↓` | Workspace kosong |
| Touchpad 3 jari ← / → | Ganti workspace |
| Touchpad 3 jari ↑ | Fullscreen |

**Sistem**

| Pintasan | Aksi |
|---|---|
| `SUPER + CTRL + R` | Muat ulang config Hyprland |
| `SUPER + SHIFT + R` | Jalankan ulang menu bar & shell |
| `SUPER + SHIFT + W` | Wallpaper acak |
| `SUPER + SHIFT + A` | Animasi on/off |
| `SUPER + SHIFT + scroll` / `SUPER + SHIFT + Z` | Zoom layar / reset |

## Kustomisasi

### Ubahan pribadi: `~/.config/hypr/lua/user.lua`

File ini dimuat paling akhir dan **tidak pernah ditimpa** saat update. Isinya contoh-contoh yang tinggal di-uncomment:

```lua
-- Monitor (lihat nama dengan: hyprctl monitors)
hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })

-- Layout keyboard
hl.config({ input = { kb_layout = "us,id" } })

-- Ganti browser
hl.unbind("SUPER + B")
hl.bind("SUPER + B", hl.dsp.exec_cmd("google-chrome-stable"))
```

### Aplikasi di dock: `~/.config/quickshell/hyprmac/dock-pinned`

Satu id aplikasi per baris, urut dari kiri. Perubahan langsung terbaca tanpa restart.
Aplikasi yang belum terpasang otomatis dilewati. Cari id aplikasi dengan:

```bash
ls /usr/share/applications ~/.local/share/applications
# contoh: org.gnome.Nautilus.desktop  ->  tulis: org.gnome.Nautilus
```

### Wallpaper

```bash
~/.config/hypr/scripts/wallpaper.sh ~/Pictures/foto.jpg   # gambar
~/.config/hypr/scripts/wallpaper.sh ~/Videos/live.mp4     # video (butuh mpvpaper)
~/.config/hypr/scripts/wallpaper.sh --random              # acak dari ~/Pictures/Wallpapers
```

Wallpaper terakhir otomatis dipulihkan saat login. Wallpaper video dijeda otomatis saat ada jendela, supaya hemat GPU dan baterai.

### Screenshot

Bawaan: disimpan ke `~/Pictures/Screenshots`, editor `swappy`. Bisa diubah di `user.lua`:

```lua
hl.env("HYPRMAC_SCREENSHOT_DIR", os.getenv("HOME") .. "/Desktop")
hl.env("HYPRMAC_SCREENSHOT_EDITOR", "gimp")
```

### Tema

Tema GTK, ikon, kursor, dan font bisa diubah di **nwg-look** (menu Apple → Pengaturan Tampilan…).

## Update

```bash
cd ~/hyprmac
git pull
./install.sh --no-packages
```

`user.lua` dan `dock-pinned` milikmu tetap dipertahankan. Cek versi di menu Apple → **Tentang Komputer Ini**. Riwayat perubahan ada di [CHANGELOG.md](CHANGELOG.md).

> Setelah **Hyprland di-update**, bangun ulang plugin title bar dengan `hyprpm update`.

## Uninstall

```bash
cd ~/hyprmac
./uninstall.sh
```

Config hyprmac dihapus dan config lamamu dikembalikan dari backup. Paket yang terpasang tidak dihapus.
Untuk mengembalikan backup tertentu: `./uninstall.sh 20260101-120000` (nama folder di `~/.config/hyprmac-backup/`).

## Pemecahan masalah

<details>
<summary><b>Tombol merah/kuning/hijau tidak muncul</b></summary>

Plugin hyprbars belum dibangun atau tidak cocok dengan versi Hyprland. Dari dalam Hyprland:

```bash
hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins   # kalau belum pernah
hyprctl reload
```
</details>

<details>
<summary><b>Dock, Island, atau notifikasi tidak muncul</b></summary>

Jalankan shell secara manual untuk melihat pesan error:

```bash
pkill -f 'qs -c hyprmac'; qs -c hyprmac
```

Notifikasi ditangani hyprmac sendiri. Kalau ada daemon notifikasi lain (swaync, dunst, mako) yang ikut berjalan dari autostart lain, matikan atau hapus dari autostart-nya.
</details>

<details>
<summary><b>Ikon aplikasi kosong / kotak</b></summary>

Pastikan `whitesur-icon-theme-git` (AUR) dan `ttf-material-symbols-variable` terpasang, lalu `SUPER + SHIFT + R`.
</details>

<details>
<summary><b>"config error" atau layar Hyprland berwarna merah setelah login</b></summary>

Lihat pesan error dengan `hyprctl configerrors`. Biasanya karena Hyprland lebih lama dari 0.56 (`Hyprland --version`) atau ada salah ketik di `user.lua`.
</details>

<details>
<summary><b>Wi-Fi / Bluetooth di Control Center tidak berfungsi</b></summary>

```bash
sudo systemctl enable --now NetworkManager bluetooth
```
</details>

## Struktur repo

```
hyprmac/
├── install.sh / uninstall.sh
├── VERSION, CHANGELOG.md
├── wallpapers/                 wallpaper bawaan
└── config/
    ├── hypr/
    │   ├── hyprland.lua        titik masuk config (Lua)
    │   ├── lua/                env, input, look, rules, keybinds, shell, autostart, hyprbars, user
    │   ├── scripts/            wallpaper, screenshot, spotlight, power, clipboard, dll.
    │   ├── hyprlock.conf       layar kunci
    │   └── hypridle.conf       redup / kunci / tidur otomatis
    ├── quickshell/hyprmac/     dock, Launchpad, Mission Control, Island, panel, dialog (QML)
    ├── waybar/                 menu bar
    └── rofi/spotlight.rasi     tema Spotlight
```

## Kredit

- [Hyprland](https://hyprland.org) dan [hyprland-plugins](https://github.com/hyprwm/hyprland-plugins) (hyprbars)
- [Quickshell](https://quickshell.org): seluruh dock, panel, dan dialog dibangun dengannya
- [Waybar](https://github.com/Alexays/Waybar), [rofi](https://github.com/davatorium/rofi)
- [WhiteSur GTK & icon theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) oleh vinceliuice
- [Bibata cursor](https://github.com/ful1e5/Bibata_Cursor) oleh ful1e5
- [Material Symbols](https://fonts.google.com/icons), [Font Awesome](https://fontawesome.com)

hyprmac tidak berafiliasi dengan Apple. macOS, Launchpad, Mission Control, dan Dynamic Island adalah merek dagang Apple Inc.; nama-nama itu dipakai di sini hanya untuk menjelaskan gaya tampilannya.

---

<div align="center">

*i use arch btw*

</div>
