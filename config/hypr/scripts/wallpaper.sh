#!/usr/bin/env bash
# Wallpaper hyprmac: gambar (hyprpaper) atau video (mpvpaper, opsional).
#   wallpaper.sh <file>     pasang gambar / video
#   wallpaper.sh --random   acak dari ~/Pictures/Wallpapers
#   wallpaper.sh            pulihkan yang terakhir (dipakai autostart)
#
# Gambar diam wallpaper juga disimpan ke ~/.cache/hyprmac/wallpaper.png,
# dipakai Mission Control dan layar kunci (hyprlock).

# xdg-user-dir mengembalikan $HOME kalau folder Pictures belum diatur
pictures=$(xdg-user-dir PICTURES 2>/dev/null)
[ -z "$pictures" ] || [ "$pictures" = "$HOME" ] && pictures="$HOME/Pictures"
dir=${HYPRMAC_WALLPAPER_DIR:-$pictures/Wallpapers}
cache="$HOME/.cache/hyprmac"
mkdir -p "$cache"
current=$(cat "$cache/current" 2>/dev/null)

case "$1" in
    --random)
        file=$(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
            -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \) ! -path "$current" | shuf -n 1)
        ;;
    "")
        file=${current:-$dir/hyprmac-default.jpg}
        ;;
    *)
        file=$(realpath "$1")
        ;;
esac

if [ ! -f "$file" ]; then
    notify-send "Wallpaper" "File tidak ditemukan: ${file:-(folder $dir kosong)}"
    exit 1
fi

# Hentikan wallpaper sebelumnya (mpvpaper kadang mengabaikan SIGTERM)
pkill -x hyprpaper
pkill -x mpvpaper
pkill -f wallpaper-autopause.py
sleep 0.3
pgrep -x mpvpaper >/dev/null && pkill -9 -x mpvpaper

case "${file,,}" in
    *.mp4 | *.webm | *.mkv | *.mov)
        if ! command -v mpvpaper >/dev/null; then
            notify-send "Wallpaper" "Wallpaper video butuh mpvpaper (AUR: mpvpaper)"
            exit 1
        fi
        ffmpeg -v error -y -i "$file" -frames:v 1 "$cache/wallpaper.png"
        mpvpaper -f -o "no-audio --loop-file=inf --panscan=1.0 --input-ipc-server=$XDG_RUNTIME_DIR/mpvpaper.sock" '*' "$file"
        # Jeda video saat ada jendela, supaya hemat GPU
        sleep 1
        "$HOME/.config/hypr/scripts/wallpaper-autopause.py" >/dev/null 2>&1 &
        ;;
    *)
        magick "$file" "$cache/wallpaper.png"
        cat > "$cache/hyprpaper.conf" <<EOF
wallpaper {
    monitor =
    path = $file
    fit_mode = cover
}

splash = false
EOF
        hyprpaper --config "$cache/hyprpaper.conf" >/dev/null 2>&1 &
        ;;
esac

disown -a
echo "$file" > "$cache/current"
