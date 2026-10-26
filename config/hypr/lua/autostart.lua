-- -----------------------------------------------------
-- Autostart
-- -----------------------------------------------------

local startup = {
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
    "hyprctl setcursor Bibata-Modern-Ice 24",
    "hypridle",
    "wl-paste --watch cliphist store",
    "~/.config/hypr/scripts/wallpaper.sh",
    "~/.config/hypr/scripts/restart-shell.sh", -- waybar + Quickshell hyprmac
}

hl.on("hyprland.start", function()
    for _, cmd in ipairs(startup) do
        hl.exec_cmd(cmd)
    end
end)
