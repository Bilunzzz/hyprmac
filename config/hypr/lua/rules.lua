-- -----------------------------------------------------
-- Window & layer rules
-- -----------------------------------------------------

-- Jendela kecil yang mengambang di tengah: { nama, class, lebar, tinggi, pin }
local floating = {
    { "pavucontrol",           "(.*org.pulseaudio.pavucontrol.*)", 700, 600, true },
    { "blueman-manager",       "(blueman-manager)",                800, 600 },
    { "nwg-look",              "(nwg-look)",                       700, 600 },
    { "gnome-calculator",      "(org.gnome.Calculator)",           700, 600 },
    { "hyprland-share-picker", "(hyprland-share-picker)",          600, 400, true },
    { "nm-connection-editor",  "(nm-connection-editor)",           800, 700 },
    { "file-chooser",          "(xdg-desktop-portal-gtk)",         900, 600 },
}

for _, r in ipairs(floating) do
    hl.window_rule({
        name   = r[1],
        match  = { class = r[2] },
        float  = true,
        center = true,
        pin    = r[5] or false,
        size   = r[3] .. " " .. r[4],
    })
end

hl.window_rule({
    name   = "Picture-in-Picture",
    match  = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float  = true,
    pin    = true,
    center = true,
})

-- Nautilus: efek kaca
hl.window_rule({
    name    = "nautilus-glass",
    match   = { class = "(org.gnome.Nautilus)" },
    opacity = "0.92 0.86",
})
