-- -----------------------------------------------------
-- Monitor, input, gesture, misc
-- -----------------------------------------------------

-- Semua monitor: resolusi bawaan, posisi otomatis.
-- Atur monitor tertentu di lua/user.lua, contoh:
--   hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

hl.config({
    input = {
        kb_layout          = "us",
        numlock_by_default = true,
        follow_mouse       = 1,
        mouse_refocus      = false,
        sensitivity        = 0,

        touchpad = {
            natural_scroll       = true,
            scroll_factor        = 1.0,
            disable_while_typing = false,
        },
    },

    misc = {
        disable_hyprland_logo      = true,
        disable_splash_rendering   = true,
        initial_workspace_tracking = 1,
        on_focus_under_fullscreen  = 1,
        allow_session_lock_restore = true,
    },

    binds = {
        workspace_back_and_forth = false,
        allow_workspace_cycles   = true,
        pass_mouse_when_bound    = false,
    },

    dwindle = {
        preserve_split = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

-- Gesture touchpad (Mission Control 4 jari ada di lua/shell.lua)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen", scale = 1.5 })
