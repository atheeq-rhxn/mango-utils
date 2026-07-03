pragma Singleton
import QtQuick
import Quickshell
import qs

Singleton {
    id: root

    property bool isShot: true
    property string captureArea: "region"
    property bool toolbarCollapsed: false

    property bool pointer: false
    property bool annotate: false
    property bool mic: false
    property bool audio: false

    property string chosenWindowIdentifier: ""
    property string chosenWindowTitle: ""
    property string chosenWindowAppId: ""

    readonly property bool hasChosenWindow: chosenWindowIdentifier !== ""

    readonly property color accentColor: isShot ? Config.ssAccent : Config.recAccent
    readonly property color pillBackground: Qt.rgba(Config.surfaceColor.r, Config.surfaceColor.g, Config.surfaceColor.b, 0.88)

    function resetWindowChoice() {
        chosenWindowIdentifier = "";
        chosenWindowTitle = "";
        chosenWindowAppId = "";
    }

    onIsShotChanged: {
        if (!isShot) {
            if (captureArea === "window")
                captureArea = "region";
            SelectionState.cancelInteraction();
            SelectionState.clampToScreen(CaptureService.activeScreen);
        }
    }

    onCaptureAreaChanged: {
        if (!CaptureService.isLoaded)
            return;
        if (captureArea !== "region") {
            toolbarCollapsed = false;
        }
    }
}
