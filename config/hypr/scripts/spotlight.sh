#!/usr/bin/env bash
# Spotlight ala macOS (rofi). Tekan lagi untuk menutup.

if pkill -x rofi; then
    exit 0
fi

rofi -show drun -i -show-icons -icon-theme WhiteSur-dark \
    -theme ~/.config/rofi/spotlight.rasi
