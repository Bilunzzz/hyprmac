-- -----------------------------------------------------
-- Tampilan: jendela ala macOS (border tipis, sudut bulat, bayangan lembut),
-- blur "liquid glass", dan animasi
-- -----------------------------------------------------

hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 10,
        border_size      = 1,
        resize_on_border = true,
        layout           = "dwindle",

        col = {
            active_border   = "rgba(ffffff30)",
            inactive_border = "rgba(ffffff14)",
        },
    },

    decoration = {
        rounding           = 12,
        active_opacity     = 1.0,
        inactive_opacity   = 0.96,
        fullscreen_opacity = 1.0,

        -- Lebih jenuh (vibrancy) supaya warna di belakang kaca tetap hidup
        blur = {
            enabled           = true,
            size              = 10,
            passes            = 3,
            vibrancy          = 0.35,
            noise             = 0.01,
            contrast          = 1.0,
            brightness        = 1.0,
            popups            = true,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = true,
        },

        shadow = {
            enabled        = true,
            range          = 40,
            render_power   = 4,
            offset         = "0 10",
            color          = "rgba(00000066)",
            color_inactive = "rgba(00000033)",
        },
    },

    animations = {
        enabled = true,
    },
})

local curves = {
    macSpring  = { { 0.32, 0.72 }, { 0, 1 } },
    md3_decel  = { { 0.05, 0.7 },  { 0.1, 1 } },
    md3_accel  = { { 0.3, 0 },     { 0.8, 0.15 } },
    menu_decel = { { 0.1, 1 },     { 0, 1 } },
    menu_accel = { { 0.38, 0.04 }, { 1, 0.07 } },
}

for name, points in pairs(curves) do
    hl.curve(name, { type = "bezier", points = points })
end

-- Jendela muncul membesar dari tengah, mengecil saat ditutup
hl.animation({ leaf = "windows",          enabled = true, speed = 3,   bezier = "macSpring",  style = "popin 85%" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 3.5, bezier = "macSpring",  style = "popin 85%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2.5, bezier = "md3_accel",  style = "popin 85%" })
hl.animation({ leaf = "border",           enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "fade",             enabled = true, speed = 3,   bezier = "md3_decel" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3,   bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 1.6, bezier = "menu_accel" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 2,   bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 4.5, bezier = "menu_accel" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 5,   bezier = "macSpring",  style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,   bezier = "md3_decel",  style = "slidevert" })
