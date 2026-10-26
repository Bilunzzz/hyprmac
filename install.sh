#!/usr/bin/env bash
# hyprmac installer: Hyprland ala macOS untuk Arch Linux.
#
#   ./install.sh              pasang paket + config (config lama dibackup)
#   ./install.sh --no-packages   hanya pasang config
#   ./install.sh --link       symlink config ke repo ini (untuk mengembangkan)
#   ./install.sh --yes        tanpa pertanyaan
#
# Config lama dipindah ke ~/.config/hyprmac-backup/<waktu>/ dan bisa
# dikembalikan dengan ./uninstall.sh

set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VERSION=$(cat "$REPO/VERSION")
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="$CONFIG/hyprmac-backup/$STAMP"

# Yang dipasang: <sumber di repo>  <tujuan>
TARGETS=(
    "config/hypr|$CONFIG/hypr"
    "config/quickshell/hyprmac|$CONFIG/quickshell/hyprmac"
    "config/waybar|$CONFIG/waybar"
    "config/rofi/spotlight.rasi|$CONFIG/rofi/spotlight.rasi"
)

# File milik pengguna yang dipertahankan saat install ulang / update
KEEP=(
    "$CONFIG/hypr/lua/user.lua"
    "$CONFIG/quickshell/hyprmac/dock-pinned"
)

PACKAGES=(
    # Hyprland & kawan-kawan
    hyprland hyprlock hypridle hyprpicker hyprpaper xdg-desktop-portal-hyprland xdg-user-dirs
    # Shell: menu bar, dock, panel, launcher
    quickshell waybar rofi
    # Aplikasi bawaan
    kitty nautilus pavucontrol nwg-look fastfetch swappy
    # Screenshot, clipboard, media, sistem
    grim slurp wl-clipboard cliphist brightnessctl playerctl jq imagemagick ffmpeg libnotify
    polkit-gnome networkmanager bluez bluez-utils wireplumber python
    # Font
    adwaita-fonts ttf-jetbrains-mono-nerd ttf-material-symbols-variable otf-font-awesome
    # Untuk membangun plugin hyprbars (hyprpm)
    git cmake meson cpio pkgconf gcc
)

AUR_PACKAGES=(
    whitesur-gtk-theme-git
    whitesur-icon-theme-git
    bibata-cursor-theme-bin
    mpvpaper # opsional: wallpaper video
)

install_packages=1
link=0
yes=0

for arg in "$@"; do
    case "$arg" in
        --no-packages) install_packages=0 ;;
        --link) link=1 ;;
        -y | --yes) yes=1 ;;
        -h | --help)
            sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Opsi tidak dikenal: $arg (lihat --help)"
            exit 1
            ;;
    esac
done

bold=$'\e[1m' blue=$'\e[34m' green=$'\e[32m' yellow=$'\e[33m' red=$'\e[31m' reset=$'\e[0m'
step() { echo -e "\n${bold}${blue}==>${reset}${bold} $*${reset}"; }
ok() { echo -e "  ${green}✓${reset} $*"; }
warn() { echo -e "  ${yellow}!${reset} $*"; }
die() {
    echo -e "${red}✗ $*${reset}"
    exit 1
}

confirm() {
    ((yes)) && return 0
    read -rp "  $1 [Y/n] " answer
    [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
}

noconfirm=()
((yes)) && noconfirm=(--noconfirm)

echo -e "${bold}hyprmac v$VERSION${reset}: Hyprland ala macOS"

# ---------------------------------------------------------------- cek awal
[ "$EUID" -eq 0 ] && die "Jalankan sebagai pengguna biasa, bukan root (sudo diminta saat perlu)."
command -v pacman >/dev/null || die "hyprmac dibuat untuk Arch Linux (pacman tidak ditemukan)."

# ------------------------------------------------------------------- paket
if ((install_packages)); then
    step "Memasang paket dari repo resmi"
    sudo pacman -S --needed "${noconfirm[@]}" "${PACKAGES[@]}"
    ok "Paket repo terpasang"

    step "Memasang paket AUR"
    helper=""
    for h in yay paru; do
        command -v "$h" >/dev/null && helper=$h && break
    done
    if [ -n "$helper" ]; then
        "$helper" -S --needed "${noconfirm[@]}" "${AUR_PACKAGES[@]}"
        ok "Paket AUR terpasang ($helper)"
    else
        warn "AUR helper (yay/paru) tidak ditemukan. Pasang manual nanti:"
        warn "  ${AUR_PACKAGES[*]}"
    fi
fi

# Hyprland 0.56+ wajib (config Lua)
if command -v Hyprland >/dev/null; then
    hv=$(Hyprland --version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 | tr -d v)
    if [ -n "$hv" ] && [ "$(printf '%s\n0.56.0\n' "$hv" | sort -V | head -1)" != "0.56.0" ]; then
        die "Hyprland $hv terlalu lama. hyprmac butuh Hyprland 0.56 atau lebih baru (config Lua)."
    fi
    ok "Hyprland ${hv:-?}"
else
    warn "Hyprland belum terpasang."
fi

# ------------------------------------------------------------------ backup
step "Membackup config lama ke ${BACKUP/#$HOME/\~}"
keep_dir=$(mktemp -d)
for f in "${KEEP[@]}"; do
    [ -f "$f" ] && mkdir -p "$keep_dir$(dirname "$f")" && cp "$f" "$keep_dir$f"
done

backed_up=0
for t in "${TARGETS[@]}"; do
    dest=${t#*|}
    # Symlink lama dari --link cukup dilepas, isinya ada di repo.
    # Config hyprmac versi lama (update) diganti tanpa backup, supaya
    # uninstall.sh tetap mengembalikan config asli sebelum hyprmac.
    if [ -L "$dest" ]; then
        rm "$dest"
    elif [ -e "$dest" ] && grep -rqs "hyprmac" "$dest"; then
        rm -r "${dest:?}"
    elif [ -e "$dest" ]; then
        mkdir -p "$BACKUP$(dirname "${dest#$HOME}")"
        mv "$dest" "$BACKUP${dest#$HOME}"
        ok "${dest/#$HOME/\~}"
        backed_up=1
    fi
done
((backed_up)) || ok "Tidak ada config lama"

# ----------------------------------------------------------------- pasang
step "Memasang config"
for t in "${TARGETS[@]}"; do
    src="$REPO/${t%%|*}"
    dest=${t#*|}
    mkdir -p "$(dirname "$dest")"
    if ((link)); then
        ln -s "$src" "$dest"
    else
        cp -r "$src" "$dest"
    fi
    ok "${dest/#$HOME/\~}"
done

# Kembalikan file milik pengguna, atau buat user.lua dari contoh
for f in "${KEEP[@]}"; do
    [ -f "$keep_dir$f" ] && cp "$keep_dir$f" "$f"
done
rm -rf "$keep_dir"
[ -f "$CONFIG/hypr/lua/user.lua" ] || cp "$CONFIG/hypr/lua/user.example.lua" "$CONFIG/hypr/lua/user.lua"

cp "$REPO/VERSION" "$CONFIG/quickshell/hyprmac/VERSION" 2>/dev/null || true
chmod +x "$CONFIG"/hypr/scripts/*

# --------------------------------------------------------------- wallpaper
step "Menyalin wallpaper"
# xdg-user-dir mengembalikan $HOME kalau folder Pictures belum diatur
pictures=$(xdg-user-dir PICTURES 2>/dev/null)
[ -z "$pictures" ] || [ "$pictures" = "$HOME" ] && pictures="$HOME/Pictures"
mkdir -p "$pictures/Wallpapers" "$pictures/Screenshots"
cp -n "$REPO"/wallpapers/* "$pictures/Wallpapers/"
ok "${pictures/#$HOME/\~}/Wallpapers"

# ----------------------------------------------------------------- tema
step "Menerapkan tema GTK, ikon, kursor, dan font"
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
    gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'
    gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
    ok "Tema diterapkan (bisa diubah lagi di nwg-look)"
else
    warn "gsettings tidak ada, lewati"
fi

# --------------------------------------------------------------- layanan
step "Layanan sistem"
for svc in NetworkManager bluetooth; do
    if systemctl is-enabled "$svc" >/dev/null 2>&1; then
        ok "$svc aktif"
    elif confirm "Aktifkan $svc (dibutuhkan Control Center)?"; then
        sudo systemctl enable --now "$svc" && ok "$svc diaktifkan"
    fi
done

# --------------------------------------------------- plugin hyprbars
step "Plugin hyprbars (tombol merah/kuning/hijau di jendela)"
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    if [ -f "/var/cache/hyprpm/$USER/hyprland-plugins/hyprbars.so" ]; then
        ok "Sudah dibangun"
    elif confirm "Bangun plugin hyprbars sekarang dengan hyprpm (butuh beberapa menit)?"; then
        hyprpm update
        { yes || true; } | hyprpm add https://github.com/hyprwm/hyprland-plugins
        ok "hyprbars dibangun"
    fi
else
    warn "Tidak sedang di dalam Hyprland. Setelah login ke Hyprland, jalankan:"
    warn "  hyprpm update && hyprpm add https://github.com/hyprwm/hyprland-plugins"
fi

# ---------------------------------------------------------------- selesai
step "Selesai! hyprmac v$VERSION terpasang"
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "  Terapkan sekarang:  hyprctl reload && ~/.config/hypr/scripts/restart-shell.sh"
    echo "  (atau logout lalu login lagi)"
else
    echo "  Logout, lalu pilih sesi Hyprland di layar login."
fi
((backed_up)) && echo "  Config lama: ${BACKUP/#$HOME/\~} (kembalikan dengan ./uninstall.sh)"
echo "  Ubahan pribadi: ~/.config/hypr/lua/user.lua"
