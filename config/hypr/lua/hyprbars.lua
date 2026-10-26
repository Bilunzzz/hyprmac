-- -----------------------------------------------------
-- Title bar dengan tombol merah/kuning/hijau (plugin hyprbars)
-- Plugin dibangun oleh install.sh lewat `hyprpm add`. Setelah Hyprland
-- di-update, bangun ulang dengan: hyprpm update
-- -----------------------------------------------------

local path = "/var/cache/hyprpm/" .. (os.getenv("USER") or "") .. "/hyprland-plugins/hyprbars.so"

-- Belum dibangun: jalan tanpa title bar
local file = io.open(path, "r")
if not file then
    return
end
file:close()

hl.plugin.load(path)

-- Hyprland membaca file ini ulang setelah plugin dimuat. Kalau plugin gagal
-- dimuat (misal versi tidak cocok setelah update Hyprland), lewati.
local loaded = false
for _, plugin in ipairs(hl.get_loaded_plugins()) do
    if plugin.name == "hyprbars" then
        loaded = true
    end
end
if not loaded then
    return
end

hl.config({
    plugin = {
        hyprbars = {
            bar_height                 = 30,
            bar_color                  = "rgba(28282ce0)",
            bar_blur                   = true,
            bar_title_enabled          = true,
            bar_text_font              = "Adwaita Sans",
            bar_text_size              = 10,
            bar_text_align             = "center",
            bar_buttons_alignment      = "left",
            bar_part_of_window         = true,
            bar_precedence_over_border = true,
            bar_padding                = 12,
            bar_button_padding         = 8,
            icon_on_hover              = true,
            inactive_button_color      = "rgba(5a5a5eff)",
            on_double_click            = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\" })'",
            col = {
                text = "rgba(ffffffb3)",
            },
        },
    },
})

-- Urutan kiri ke kanan: tutup, minimize, zoom.
-- Minimize memindahkan jendela ke workspace tersembunyi; klik ikonnya di dock
-- untuk mengembalikan.
local buttons = {
    { "rgb(ff5f57)", "rgb(4d0000)", "󰅖", "hyprctl dispatch 'hl.dsp.window.close()'" },
    { "rgb(febc2e)", "rgb(5a3e00)", "󰍴", "hyprctl dispatch 'hl.dsp.window.move({ workspace = \"special:minimized\", follow = false })'" },
    { "rgb(28c840)", "rgb(00450d)", "󰊓", "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\" })'" },
}

-- hyprbars menambah tombol dari tepi ke dalam, jadi daftar dibalik
for i = #buttons, 1, -1 do
    local b = buttons[i]
    hl.plugin.hyprbars.add_button({
        bg_color = b[1],
        fg_color = b[2],
        size     = 13,
        icon     = b[3],
        action   = b[4],
    })
end

-- Tanpa title bar untuk Picture-in-Picture dan rofi
hl.window_rule({ name = "hyprbars-off-pip",  match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, ["hyprbars:no_bar"] = true })
hl.window_rule({ name = "hyprbars-off-rofi", match = { class = "^(Rofi|rofi)$" }, ["hyprbars:no_bar"] = true })
