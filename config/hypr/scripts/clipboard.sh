#!/usr/bin/env bash
# Riwayat clipboard (cliphist) dengan tampilan Spotlight. Tekan lagi untuk menutup.

if pkill -x rofi; then
    exit 0
fi

cliphist list |
    rofi -dmenu -i -p "Clipboard" -display-columns 2 -theme ~/.config/rofi/spotlight.rasi |
    cliphist decode |
    wl-copy
