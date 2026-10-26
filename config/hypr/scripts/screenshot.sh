#!/usr/bin/env bash
# Pengambil screenshot untuk toolbar ala macOS (Quickshell ScreenshotBar).
#   screenshot.sh <screen|window|area> <save|clipboard|edit> [tunda_detik]
#
# Bisa diatur lewat variabel lingkungan (mis. di lua/user.lua dengan hl.env):
#   HYPRMAC_SCREENSHOT_DIR     folder simpan    (bawaan: ~/Pictures/Screenshots)
#   HYPRMAC_SCREENSHOT_EDITOR  editor + argumen (bawaan: swappy -f)

mode=${1:-area}
dest=${2:-save}
delay=${3:-0}

# xdg-user-dir mengembalikan $HOME kalau folder Pictures belum diatur
pictures=$(xdg-user-dir PICTURES 2>/dev/null)
[ -z "$pictures" ] || [ "$pictures" = "$HOME" ] && pictures="$HOME/Pictures"
folder=${HYPRMAC_SCREENSHOT_DIR:-$pictures/Screenshots}
editor=${HYPRMAC_SCREENSHOT_EDITOR:-swappy -f}
name="Screenshot $(date '+%Y-%m-%d at %H.%M.%S').png"

island() { qs -c hyprmac ipc call island "$@" >/dev/null 2>&1; }

case "$mode" in
    screen)
        output=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
        ;;
    window)
        # Pilih jendela dengan klik (kotak tiap jendela di workspace aktif)
        ws=$(hyprctl activeworkspace -j | jq '.id')
        geometry=$(hyprctl clients -j | jq -r --argjson ws "$ws" \
            '.[] | select(.workspace.id == $ws and .hidden == false) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' |
            slurp -r -b "#00000040" -c "#0a84ffff" -B "#0a84ff30" -w 2) || exit 0
        ;;
    area)
        # Bekukan layar selama memilih area
        hyprpicker -r -z &
        picker=$!
        sleep 0.1
        geometry=$(slurp -b "#00000060" -c "#ffffffff" -w 1 -d)
        kill "$picker" 2>/dev/null
        [ -z "$geometry" ] && exit 0
        ;;
    *)
        echo "Pemakaian: screenshot.sh <screen|window|area> <save|clipboard|edit> [tunda_detik]"
        exit 1
        ;;
esac

# Hitung mundur di Dynamic Island
for ((i = delay; i > 0; i--)); do
    island countdown "$i"
    sleep 1
done
[ "$delay" -gt 0 ] && sleep 0.4 # tunggu Island kembali kecil

tmp=$(mktemp --suffix=.png)
if [ "$mode" = screen ]; then
    grim -o "$output" "$tmp"
else
    grim -g "$geometry" "$tmp"
fi || exit 1

case "$dest" in
    clipboard)
        wl-copy < "$tmp"
        notify-send -a Screenshot -i "$tmp" "Screenshot disalin" "Tersimpan di papan klip"
        ;;
    edit)
        mkdir -p "$folder"
        mv "$tmp" "$folder/$name"
        $editor "$folder/$name" & # boleh berisi argumen, mis. "swappy -f"
        disown
        ;;
    *)
        mkdir -p "$folder"
        mv "$tmp" "$folder/$name"
        wl-copy < "$folder/$name"
        notify-send -a Screenshot -i "$folder/$name" "Screenshot" "Disimpan ke ${folder/#$HOME/\~}"
        ;;
esac
