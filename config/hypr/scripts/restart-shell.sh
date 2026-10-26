#!/usr/bin/env bash
# Jalankan (ulang) shell hyprmac: menu bar waybar + Quickshell hyprmac.
# Dipakai autostart dan SUPER + SHIFT + R.
#
# Quickshell hyprmac juga menjadi server notifikasi, jadi daemon notifikasi
# lain (swaync, dunst, mako) dihentikan dulu: hanya satu yang boleh aktif.

pkill -x waybar
pkill -f '^(qs|quickshell) -c hyprmac'
pkill -x swaync
pkill -x dunst
pkill -x mako
sleep 0.3

waybar >/dev/null 2>&1 &
qs -c hyprmac >/dev/null 2>&1 &
disown -a
