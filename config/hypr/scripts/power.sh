#!/usr/bin/env bash
# Aksi daya, dipakai menu Apple dan dialog daya Quickshell.
#   power.sh lock | exit | reboot | shutdown | suspend | hibernate
# exit/reboot/shutdown menutup aplikasi dengan rapi dulu (SIGTERM, tunggu
# maksimal 5 detik) supaya data yang belum tersimpan tidak hilang begitu saja.

source ~/.config/hypr/scripts/hypr-lib.sh

terminate_clients() {
    local timeout=5 start pid
    local -a pids
    mapfile -t pids < <(hyprctl clients -j | jq -r '.[].pid')

    for pid in "${pids[@]}"; do
        kill -15 "$pid" 2>/dev/null
    done

    start=$(date +%s)
    for pid in "${pids[@]}"; do
        while kill -0 "$pid" 2>/dev/null; do
            (($(date +%s) - start >= timeout)) && return 0
            sleep 0.5
        done
    done
}

case "$1" in
    lock)
        # Layar kunci Quickshell; hyprlock kalau shell tidak berjalan
        qs -c hyprmac ipc call lock lock 2>/dev/null || pidof hyprlock || hyprlock
        ;;
    exit)
        terminate_clients
        hypr_exit
        ;;
    reboot)
        terminate_clients
        systemctl reboot
        ;;
    shutdown)
        terminate_clients
        systemctl poweroff
        ;;
    suspend)
        systemctl suspend
        ;;
    hibernate)
        systemctl hibernate
        ;;
    *)
        echo "Pemakaian: power.sh lock|exit|reboot|shutdown|suspend|hibernate"
        exit 1
        ;;
esac
