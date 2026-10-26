-- -----------------------------------------------------
-- Environment variables
-- -----------------------------------------------------

local envs = {
    XDG_CURRENT_DESKTOP                 = "Hyprland",
    XDG_SESSION_TYPE                    = "wayland",
    XDG_SESSION_DESKTOP                 = "Hyprland",
    QT_QPA_PLATFORM                     = "wayland;xcb",
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
    QT_AUTO_SCREEN_SCALE_FACTOR         = "1",
    GDK_BACKEND                         = "wayland,x11,*",
    CLUTTER_BACKEND                     = "wayland",
    MOZ_ENABLE_WAYLAND                  = "1",
    XCURSOR_THEME                       = "Bibata-Modern-Ice",
    XCURSOR_SIZE                        = "24",
    HYPRCURSOR_SIZE                     = "24",
    OZONE_PLATFORM                      = "wayland",
    ELECTRON_OZONE_PLATFORM_HINT        = "wayland",
    SDL_VIDEODRIVER                     = "wayland",
}

for name, value in pairs(envs) do
    hl.env(name, value)
end
