pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    Process {
        id: shotProcess

        running: false

        onExited: (code, status) => {
            freezeState.exit();
            globalState.windowsVisible = false;
            if (!castState.isCasting)
                Qt.quit();
        }
    }

    function buildArgs(sub, forShot) {
        const a = [Config.msnapPath, sub];
        if (captureState.captureArea === "region" && selectionState.rectWidth > selectionState.minimumSize && selectionState.rectHeight > selectionState.minimumSize) {
            const rx = Math.round(selectionState.rectX);
            const ry = Math.round(selectionState.rectY);
            const rw = Math.round(selectionState.rectWidth);
            const rh = Math.round(selectionState.rectHeight);
            a.push("-g", `${rx},${ry} ${rw}x${rh}`);
        } else if (captureState.captureArea === "window") {
            a.push("-w");
        }

        if (forShot) {
            if (captureState.pointer)
                a.push("-p");
            if (captureState.annotate)
                a.push("-a");
        } else {
            if (captureState.mic)
                a.push("-m");
            if (captureState.audio)
                a.push("-a");
        }
        return a;
    }

    function executeAction() {
        if (captureState.captureArea === "region" && (selectionState.rectWidth <= selectionState.minimumSize || selectionState.rectHeight <= selectionState.minimumSize))
            return;
        captureState.isShot ? doShot() : castState.doCast();
    }

    function doShot() {
        globalState.windowsVisible = false;
        shotProcess.command = buildArgs("shot", true);
        shotProcess.running = true;
    }

    function closeAll() {
        freezeState.exit();
        globalState.windowsVisible = false;
        if (!castState.isCasting)
            Qt.quit();
    }
}
