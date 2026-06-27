pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Scope {
    id: root

    property bool isShot: true
    property string captureArea: "region"
    property bool toolbarCollapsed: false

    property bool pointer: false
    property bool annotate: false
    property bool mic: false
    property bool audio: false

    readonly property color accentColor: isShot ? Config.ssAccent : Config.recAccent
    readonly property color pillBackground: Qt.rgba(Config.surfaceColor.r, Config.surfaceColor.g, Config.surfaceColor.b, 0.88)

    onIsShotChanged: {
        if (!isShot) {
            if (captureArea === "window")
                captureArea = "region";
            selectionState.cancelInteraction();
            selectionState.clampToScreen(activeScreen);
        }
    }

    onCaptureAreaChanged: {
        if (!captureService.isLoaded)
            return;
        if (captureArea !== "region") {
            toolbarCollapsed = false;
            selectionState.clear();
        }
    }
}
