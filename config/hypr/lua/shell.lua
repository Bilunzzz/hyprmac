-- -----------------------------------------------------
-- Shell hyprmac: menu bar (waybar) + Quickshell (~/.config/quickshell/hyprmac):
-- dock, Launchpad, Mission Control, Dynamic Island, Control Center,
-- Notification Center, menu Apple, dialog daya, toolbar screenshot.
-- -----------------------------------------------------

local qs = "qs -c hyprmac ipc call "
local scripts = "~/.config/hypr/scripts"

-- Blur di belakang menu bar dan Spotlight
for _, ns in ipairs({ "waybar", "rofi" }) do
    hl.layer_rule({ match = { namespace = ns }, blur = true, ignore_alpha = 0.05 })
end

-- Panel Quickshell punya animasi sendiri, jadi animasi layer Hyprland dimatikan
for _, ns in ipairs({ "macshell-dock", "macshell-launchpad", "macshell-notifications", "macshell-center",
                     "macshell-menu", "macshell-dialog", "macshell-screenshot", "macshell-mission" }) do
    hl.layer_rule({ match = { namespace = ns }, blur = true, ignore_alpha = 0.05, no_anim = true })
end
hl.layer_rule({ match = { namespace = "macshell-island" }, no_anim = true })

-- Spotlight, Launchpad, Mission Control, Notification Center
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(scripts .. "/spotlight.sh"))
hl.bind("SUPER + A",     hl.dsp.exec_cmd(qs .. "launchpad toggle"))
hl.bind("SUPER + grave", hl.dsp.exec_cmd(qs .. "missioncontrol toggle"))
hl.bind("SUPER + N",     hl.dsp.exec_cmd(qs .. "notifications toggle"))

-- Gesture 4 jari ke atas / bawah: buka / tutup Mission Control
hl.gesture({ fingers = 4, direction = "up",   action = function() hl.exec_cmd(qs .. "missioncontrol open") end })
hl.gesture({ fingers = 4, direction = "down", action = function() hl.exec_cmd(qs .. "missioncontrol close") end })

-- Toolbar screenshot ala ⌘⇧5 (Langsung / Tunda)
hl.bind("PRINT",         hl.dsp.exec_cmd(qs .. "screenshot open"))
hl.bind("SUPER + PRINT", hl.dsp.exec_cmd(qs .. "screenshot open"))

-- Dialog daya ala macOS (Mulai Ulang / Tidur / Matikan)
hl.bind("SUPER + CTRL + Q", hl.dsp.exec_cmd(qs .. "power open power"))

-- Tombol kecerahan memunculkan OSD di Dynamic Island
-- (volume tidak perlu: Island membaca perubahan volume langsung dari PipeWire)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -q s +10% && " .. qs .. "island brightness"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q s 10%- && " .. qs .. "island brightness"), { repeating = true })
