import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// Layar kunci hyprmac (Wayland session lock + PAM).
//   qs -c hyprmac ipc call lock lock      kunci layar
//   qs -c hyprmac ipc call lock preview   pratinjau tanpa mengunci (Esc untuk keluar)
//   qs -c hyprmac ipc call lock previewAs expanded|lyrics
//
// Darurat (layar kunci bermasalah): pindah ke TTY dengan Ctrl+Alt+F3, login, lalu
//   hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock")'
// dan buka dengan hyprlock seperti biasa.
Scope {
    id: root

    property bool previewOpen: false
    property string previewMode: "compact"

    // Status kata sandi, dibaca LockScreen.qml
    QtObject {
        id: authState

        property string buffer: ""
        property string state: "" // "", checking, failed, locked

        function handleKey(event): void {
            if (event.key === Qt.Key_Escape && root.previewOpen) {
                root.previewOpen = false;
                buffer = "";
                return;
            }
            if (state === "checking")
                return;

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.previewOpen) {
                    // Pratinjau tidak memeriksa kata sandi sungguhan
                    buffer = "";
                    state = "failed";
                    resetState.restart();
                } else {
                    state = "checking";
                    pam.start();
                }
            } else if (event.key === Qt.Key_Backspace) {
                buffer = (event.modifiers & Qt.ControlModifier) ? "" : buffer.slice(0, -1);
            } else if (event.key === Qt.Key_Escape) {
                buffer = "";
            } else if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
                buffer += event.text;
                if (state === "failed")
                    state = "";
            }
            event.accepted = true;
        }
    }

    PamContext {
        id: pam

        config: "passwd"
        configDirectory: Quickshell.shellPath("pam")

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(authState.buffer);
            authState.buffer = "";
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                authState.state = "";
                root.unlock();
                return;
            }
            authState.buffer = "";
            authState.state = result === PamResult.MaxTries ? "locked" : "failed";
            resetState.restart();
        }
    }

    Timer {
        id: resetState
        interval: 3000
        onTriggered: authState.state = ""
    }

    property bool unlocking: false

    function unlock(): void {
        unlocking = true;
        unlockTimer.restart();
    }

    // Tunggu animasi meluncur ke atas selesai, baru lepas kunci
    Timer {
        id: unlockTimer
        interval: 540
        onTriggered: {
            session.locked = false;
            root.unlocking = false;
        }
    }

    WlSessionLock {
        id: session

        WlSessionLockSurface {
            color: "transparent"

            LockScreen {
                anchors.fill: parent
                auth: authState
                unlocking: root.unlocking
            }
        }
    }

    // Pratinjau: tampilan yang sama di jendela biasa, tanpa mengunci sesi
    LazyLoader {
        active: root.previewOpen

        PanelWindow {
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "black"

            WlrLayershell.namespace: "macshell-lockpreview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            LockScreen {
                anchors.fill: parent
                auth: authState
                mode: root.previewMode
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            authState.buffer = "";
            authState.state = "";
            session.locked = true;
        }

        function preview(): void {
            root.previewMode = "compact";
            root.previewOpen = !root.previewOpen;
        }

        // Pratinjau dengan tampilan tertentu: compact | expanded | lyrics
        function previewAs(mode: string): void {
            root.previewMode = mode;
            root.previewOpen = true;
        }

        function isLocked(): bool {
            return session.locked;
        }
    }
}
