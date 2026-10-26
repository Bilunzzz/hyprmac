--  _
-- | |__  _   _ _ __  _ __ _ __ ___   __ _  ___
-- | '_ \| | | | '_ \| '__| '_ ` _ \ / _` |/ __|
-- | | | | |_| | |_) | |  | | | | | | (_| | (__
-- |_| |_|\__, | .__/|_|  |_| |_| |_|\__,_|\___|
--        |___/|_|
--
-- hyprmac: Hyprland ala macOS (config Lua, Hyprland 0.56+)
-- Modul ada di ~/.config/hypr/lua/. Ubahan pribadi taruh di lua/user.lua
-- supaya tidak tertimpa saat update.

require("lua.env")
require("lua.input")
require("lua.look")
require("lua.rules")
require("lua.keybinds")
require("lua.shell")
require("lua.autostart")

-- Plugin title bar (tombol merah/kuning/hijau). Pakai dofile, bukan require:
-- Hyprland membaca config ulang setelah plugin dimuat.
dofile(os.getenv("HOME") .. "/.config/hypr/lua/hyprbars.lua")

-- Ubahan pribadi (opsional, tidak disentuh install.sh)
pcall(require, "lua.user")
