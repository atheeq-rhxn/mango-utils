pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "components"

Scope {
    PanelWindow {
        anchors.top: true
        anchors.left: true
        anchors.right: true
        anchors.bottom: true
        color: "transparent"
        visible: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "msnap-chooser"

        WindowPicker {
            id: chooser
            anchors.fill: parent
            active: true

            onAccepted: (title, identifier, appId) => {
                selectionFile.setText(identifier + "\n")
                Qt.callLater(Qt.quit)
            }
            onCancelled: {
                Qt.callLater(Qt.quit)
            }
        }

        FileView {
            id: selectionFile
            path: Quickshell.env("XDG_RUNTIME_DIR") + "/msnap-chooser"
            blockWrites: true
            printErrors: false
        }
    }
}
