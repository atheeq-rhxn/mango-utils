pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string state: "idle"

    Process {
        id: wayfreezeProcess

        command: ["wayfreeze", "--enable-keyboard", "--hide-cursor", "--after-freeze-cmd", "echo frozen"]

        running: false

        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf("frozen") !== -1) {
                    root.state = "frozen";
                    captureService.windowsVisible = true;
                }
            }
        }

        onExited: (code, status) => {
            if (root.state !== "idle") {
                root.state = "idle";
            }
        }
    }

    function enter() {
        if (root.state !== "idle")
            return;
        if (!Config.freezeEnabled) {
            root.state = "frozen";
            captureService.windowsVisible = true;
            return;
        }
        root.state = "freezing";
        captureService.windowsVisible = false;
        wayfreezeProcess.running = true;
    }

    function exit() {
        if (wayfreezeProcess.running)
            wayfreezeProcess.running = false;
        root.state = "idle";
    }
}
