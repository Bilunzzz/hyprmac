#!/usr/bin/env bash
# Toggle animasi Hyprland on/off

source ~/.config/hypr/scripts/hypr-lib.sh

cache_file="$HOME/.cache/toggle_animation"

if [ -f "$cache_file" ]; then
    hypr_set animations:enabled true
    rm "$cache_file"
else
    hypr_set animations:enabled false
    touch "$cache_file"
fi
