pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool isCasting: false
    property bool isTransitioningToCast: false
    property bool showCastAlert: false
    property int castSeconds: 0
    property int castStartEpoch: 0

    FileView {
        id: startTimeFile
        path: "/tmp/msnap-cast.starttime"
        watchChanges: false
        printErrors: false
        onLoaded: {
            const t = parseInt(text().trim(), 10);
            if (!isNaN(t))
                castStartEpoch = t;
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: isCasting
        onTriggered: castSeconds = castStartEpoch > 0 ? Math.floor(Date.now() / 1000) - castStartEpoch : castSeconds + 1
        onRunningChanged: {
            if (running) {
                startTimeFile.reload();
            } else {
                castSeconds = 0;
                castStartEpoch = 0;
            }
        }
    }

    Timer {
        id: castTransitionTimer
        interval: 400
        repeat: false
        onTriggered: {
            isTransitioningToCast = false;
            freezeState.exit();
            const a = captureService.buildArgs("cast", false);
            a.push("--toggle");
            Quickshell.execDetached(a);
            isCasting = true;
            globalState.windowsVisible = false;
        }
    }

    FileView {
        path: Config.pidFilePath
        watchChanges: true
        printErrors: false
        onLoaded: {
            isCasting = true;
            showCastAlert = true;
            startTimeFile.reload();
            castAlertTimer.start();
        }
        onLoadFailed: {
            if (isCasting) {
                isCasting = false;
                if (!globalState.windowsVisible)
                    quitTimer.start();
            }
        }
    }

    Timer {
        id: quitTimer
        interval: 600
        repeat: false
        onTriggered: Qt.quit()
    }

    Timer {
        id: castAlertTimer
        interval: 2000
        repeat: false
        onTriggered: {
            showCastAlert = false;
            globalState.windowsVisible = false;
        }
    }

    function doCast() {
        if (isCasting)
            return;
        isTransitioningToCast = true;
        castTransitionTimer.start();
    }

    function stopCast() {
        if (!isCasting)
            return;
        Quickshell.execDetached([Config.msnapPath, "cast", "--toggle"]);
        isCasting = false;
        if (!globalState.windowsVisible)
            quitTimer.start();
    }

    function formatTime(s) {
        const m = Math.floor(s / 60);
        const sec = s % 60;
        return (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
    }
}
