-- -----------------------------------------------------
-- Key bindings (SUPER = tombol Windows/⌘)
-- Pintasan khusus shell (Spotlight, Launchpad, Mission Control, screenshot,
-- dialog daya) ada di lua/shell.lua.
-- -----------------------------------------------------

-- Aplikasi bawaan. Ganti di lua/user.lua, contoh:
--   hl.unbind("SUPER + B"); hl.bind("SUPER + B", hl.dsp.exec_cmd("google-chrome-stable"))
local apps = {
    terminal = "kitty",
    browser  = "firefox",
    files    = "nautilus --new-window",
}

local mainMod = "SUPER"
local scripts = "~/.config/hypr/scripts"

local function bind(keys, action, opts)
    hl.bind(keys, action, opts)
end

local function exec(cmd)
    return hl.dsp.exec_cmd(cmd)
end

-- Aplikasi
bind(mainMod .. " + RETURN", exec(apps.terminal))
bind(mainMod .. " + B",      exec(apps.browser))
bind(mainMod .. " + E",      exec(apps.files))

-- Zoom layar
bind(mainMod .. " + SHIFT + mouse_down", exec(scripts .. "/zoom.sh in"))
bind(mainMod .. " + SHIFT + mouse_up",   exec(scripts .. "/zoom.sh out"))
bind(mainMod .. " + SHIFT + Z",          exec(scripts .. "/zoom.sh reset"))

-- Jendela
bind(mainMod .. " + Q",         hl.dsp.window.close())
bind(mainMod .. " + SHIFT + Q", exec("hyprctl activewindow -j | jq '.pid' | xargs kill"))
bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind(mainMod .. " + M",         hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(mainMod .. " + T",         hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + SHIFT + T", exec(scripts .. "/toggleallfloat.sh"))
bind(mainMod .. " + G",         hl.dsp.group.toggle())

for _, dir in ipairs({ "left", "right", "up", "down" }) do
    bind(mainMod .. " + " .. dir,       hl.dsp.focus({ direction = dir }))
    bind(mainMod .. " + ALT + " .. dir, hl.dsp.window.swap({ direction = dir }))
end

bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 100,  y = 0,    relative = true }))
bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -100, y = 0,    relative = true }))
bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,    y = 100,  relative = true }))
bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,    y = -100, relative = true }))

bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

bind("ALT + Tab", hl.dsp.window.cycle_next(),   { repeating = true })
bind("ALT + Tab", hl.dsp.window.bring_to_top(), { repeating = true })

-- Sistem
bind(mainMod .. " + CTRL + R",  exec("hyprctl reload"))
bind(mainMod .. " + SHIFT + R", exec(scripts .. "/restart-shell.sh"))
bind(mainMod .. " + SHIFT + A", exec(scripts .. "/toggle-animations.sh"))
bind(mainMod .. " + CTRL + L",  exec(scripts .. "/power.sh lock"))
bind(mainMod .. " + V",         exec(scripts .. "/clipboard.sh"))
bind(mainMod .. " + SHIFT + W", exec(scripts .. "/wallpaper.sh --random"))

-- Screenshot instan (toolbar ⌘⇧5 ada di Print, lihat lua/shell.lua)
bind(mainMod .. " + ALT + F", exec(scripts .. "/screenshot.sh screen save"))
bind(mainMod .. " + ALT + S", exec(scripts .. "/screenshot.sh area save"))

-- Workspace
for i = 1, 10 do
    local key = i % 10 -- workspace 10 = tombol 0
    bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    bind(mainMod .. " + CTRL + " .. key,  exec(scripts .. "/moveTo.sh " .. i))
end

bind(mainMod .. " + Tab",         hl.dsp.focus({ workspace = "m+1" }))
bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))
bind(mainMod .. " + mouse_down",  hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up",    hl.dsp.focus({ workspace = "e-1" }))
bind(mainMod .. " + CTRL + down", hl.dsp.focus({ workspace = "empty" }))

-- Tombol Fn (kecerahan ada di lua/shell.lua, dengan OSD Dynamic Island)
local held = { locked = true, repeating = true }
bind("XF86AudioRaiseVolume", exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), held)
bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      held)
bind("XF86AudioMute",        exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
bind("XF86AudioMicMute",     exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
bind("XF86AudioPlay",        exec("playerctl play-pause"))
bind("XF86AudioPause",       exec("playerctl pause"))
bind("XF86AudioNext",        exec("playerctl next"))
bind("XF86AudioPrev",        exec("playerctl previous"))
