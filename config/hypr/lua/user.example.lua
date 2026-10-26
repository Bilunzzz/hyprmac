-- -----------------------------------------------------
-- Ubahan pribadi. install.sh menyalin file ini menjadi lua/user.lua
-- sekali saja, lalu tidak pernah menimpanya lagi saat update.
-- Dimuat paling akhir, jadi bisa menimpa apa pun dari modul lain.
-- -----------------------------------------------------

-- Monitor (lihat nama output dengan: hyprctl monitors)
-- hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })

-- Layout keyboard
-- hl.config({ input = { kb_layout = "us,id" } })

-- Ganti browser
-- hl.unbind("SUPER + B")
-- hl.bind("SUPER + B", hl.dsp.exec_cmd("google-chrome-stable"))

-- Tanpa transparansi jendela tidak aktif
-- hl.config({ decoration = { inactive_opacity = 1.0 } })
