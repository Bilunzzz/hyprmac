#!/usr/bin/env bash
# Toggle floating/tiling untuk semua jendela di workspace aktif

source ~/.config/hypr/scripts/hypr-lib.sh

workspace=$(hyprctl activeworkspace -j | jq '.id')
for address in $(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $workspace) | .address"); do
    hypr_toggle_float "$address" >/dev/null
done

notify-send "Jendela" "Semua jendela di workspace ini diubah floating/tiling"
