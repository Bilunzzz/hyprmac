#!/usr/bin/env bash
# Pindahkan semua jendela workspace aktif ke workspace lain, lalu ikut pindah.
#   moveTo.sh <workspace>

source ~/.config/hypr/scripts/hypr-lib.sh

target=$1
[ -z "$target" ] && { echo "Pemakaian: moveTo.sh <workspace>"; exit 1; }

current=$(hyprctl activeworkspace -j | jq '.id')
for address in $(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $current) | .address"); do
    hypr_move_window_silent "$target" "$address" >/dev/null
done

hypr_workspace "$target" >/dev/null
