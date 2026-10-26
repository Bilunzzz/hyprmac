#!/usr/bin/env bash
# Lepas hyprmac dan kembalikan config dari backup terakhir install.sh.
#   ./uninstall.sh            kembalikan backup terbaru
#   ./uninstall.sh <waktu>    kembalikan backup tertentu (nama folder di
#                             ~/.config/hyprmac-backup/)
# Paket yang terpasang tidak dihapus.

set -euo pipefail

CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
BACKUPS="$CONFIG/hyprmac-backup"

TARGETS=(
    "$CONFIG/hypr"
    "$CONFIG/quickshell/hyprmac"
    "$CONFIG/waybar"
    "$CONFIG/rofi/spotlight.rasi"
)

if [ -n "${1:-}" ]; then
    backup="$BACKUPS/$1"
else
    backup=$(find "$BACKUPS" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1)
fi

if [ -z "$backup" ] || [ ! -d "$backup" ]; then
    echo "Tidak ada backup di ${BACKUPS/#$HOME/\~}."
    read -rp "Hapus config hyprmac tanpa mengembalikan apa pun? [y/N] " answer
    [[ "$answer" =~ ^[Yy] ]] || exit 0
fi

for dest in "${TARGETS[@]}"; do
    if [ -L "$dest" ]; then
        rm "$dest"
    elif [ -e "$dest" ]; then
        rm -r "$dest"
    fi
    echo "Dihapus:      ${dest/#$HOME/\~}"

    if [ -n "$backup" ] && [ -e "$backup${dest#$HOME}" ]; then
        mv "$backup${dest#$HOME}" "$dest"
        echo "Dikembalikan: ${dest/#$HOME/\~}"
    fi
done

# Hapus folder backup yang sudah kosong (hanya di dalam folder backup itu)
if [ -n "$backup" ]; then
    find "$backup" -depth -type d -empty -delete
fi

echo
echo "Selesai. Logout lalu login lagi (atau: hyprctl reload) untuk menerapkan."
