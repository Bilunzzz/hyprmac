#!/usr/bin/env bash
# Perintah Hyprland untuk config Lua (Hyprland 0.56+): `hyprctl keyword` tidak
# bisa dipakai dan `hyprctl dispatch` memakai sintaks hl.dsp.
#
# Dari script:   source ~/.config/hypr/scripts/hypr-lib.sh; hypr_set animations:enabled false
# Dari perintah: ~/.config/hypr/scripts/hypr-lib.sh dpms off

# hypr_set <opsi:dengan:titik-dua> <nilai>   (nilai: angka atau true/false)
hypr_set() {
    local key=$1 table=$2
    local -a parts
    IFS=':' read -ra parts <<<"$key"
    for ((i = ${#parts[@]} - 1; i >= 0; i--)); do
        table="{ ${parts[i]} = $table }"
    done
    hyprctl eval "hl.config($table)" >/dev/null
}

hypr_exit() {
    hyprctl dispatch 'hl.dsp.exit()'
}

# hypr_dpms on|off
hypr_dpms() {
    hyprctl dispatch "hl.dsp.dpms({ action = \"$1\" })"
}

# hypr_workspace <id>
hypr_workspace() {
    hyprctl dispatch "hl.dsp.focus({ workspace = $1 })"
}

# hypr_move_window_silent <workspace> <address>
hypr_move_window_silent() {
    hyprctl dispatch "hl.dsp.window.move({ workspace = $1, window = \"address:$2\", follow = false })"
}

# hypr_toggle_float <address>
hypr_toggle_float() {
    hyprctl dispatch "hl.dsp.window.float({ action = \"toggle\", window = \"address:$1\" })"
}

# Dijalankan langsung: hypr-lib.sh <perintah> [argumen...]
if [ "${BASH_SOURCE[0]}" = "$0" ] && [ -n "$1" ]; then
    cmd=$1
    shift
    "hypr_$cmd" "$@"
fi
