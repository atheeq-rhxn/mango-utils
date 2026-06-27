pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    property var activeScreen: null
    property bool windowsVisible: true
    property bool isLoaded: false

    onWindowsVisibleChanged: {
        if (!windowsVisible)
            SelectionState.cancelInteraction();
    }

    Process {
        id: shotProcess

        running: false

        onExited: (code, status) => {
            FreezeState.exit();
            root.windowsVisible = false;
            if (!CastState.isCasting)
                Qt.quit();
        }
    }

    function buildArgs(sub, forShot) {
        const a = [Config.msnapPath, sub];
        if (CaptureState.captureArea === "region" && SelectionState.rectWidth > SelectionState.minimumSize && SelectionState.rectHeight > SelectionState.minimumSize) {
            const rx = Math.round(SelectionState.rectX);
            const ry = Math.round(SelectionState.rectY);
            const rw = Math.round(SelectionState.rectWidth);
            const rh = Math.round(SelectionState.rectHeight);
            a.push("-g", `${rx},${ry} ${rw}x${rh}`);
        } else if (CaptureState.captureArea === "window") {
            a.push("-w");
        }

        if (forShot) {
            if (CaptureState.pointer)
                a.push("-p");
            if (CaptureState.annotate)
                a.push("-a");
        } else {
            if (CaptureState.mic)
                a.push("-m");
            if (CaptureState.audio)
                a.push("-a");
        }
        return a;
    }

    function executeAction() {
        if (CaptureState.captureArea === "region" && (SelectionState.rectWidth <= SelectionState.minimumSize || SelectionState.rectHeight <= SelectionState.minimumSize))
            return;
        CaptureState.isShot ? doShot() : CastState.doCast();
    }

    function doShot() {
        root.windowsVisible = false;
        shotProcess.command = buildArgs("shot", true);
        shotProcess.running = true;
    }

    function closeAll() {
        FreezeState.exit();
        root.windowsVisible = false;
        if (!CastState.isCasting)
            Qt.quit();
    }
}
