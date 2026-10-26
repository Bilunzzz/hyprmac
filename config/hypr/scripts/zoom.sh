#!/usr/bin/env bash
# Zoom layar: zoom.sh in | out | reset

source ~/.config/hypr/scripts/hypr-lib.sh

current=$(hyprctl getoption cursor:zoom_factor -j | jq '.float // .value // 1')

case "$1" in
    in)    new=$(awk "BEGIN { print $current + 0.5 }") ;;
    out)   new=$(awk "BEGIN { v = $current - 0.5; print (v < 1 ? 1 : v) }") ;;
    reset) new=1 ;;
    *)     echo "Pemakaian: zoom.sh in|out|reset"; exit 1 ;;
esac

hypr_set cursor:zoom_factor "$new"
