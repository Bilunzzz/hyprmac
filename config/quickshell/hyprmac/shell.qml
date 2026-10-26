//@ pragma IconTheme WhiteSur-dark
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// Shell ala macOS: dock (zoom), Launchpad (geser per halaman), Dynamic Island,
// notifikasi + Notification Center liquid glass.
// Dijalankan oleh ~/.config/hypr/scripts/restart-shell.sh (autostart)
//   qs -c hyprmac ipc call launchpad toggle
//   qs -c hyprmac ipc call notifications toggle
//   qs -c hyprmac ipc call controlcenter toggle
//   qs -c hyprmac ipc call applemenu toggle
//   qs -c hyprmac ipc call power open shutdown|restart|logout|power
//   qs -c hyprmac ipc call screenshot open
//   qs -c hyprmac ipc call missioncontrol toggle
//   qs -c hyprmac ipc call island brightness

import QtQuick
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property ShellScreen modelData

            Dock {
                screen: perScreen.modelData
            }

            Island {
                screen: perScreen.modelData
            }
        }
    }

    Launchpad {}

    NotificationPopups {}

    NotificationCenter {}

    ControlCenter {}

    AppleMenu {}

    AboutWindow {}

    PowerDialog {}

    ScreenshotBar {}

    MissionControl {}
}
