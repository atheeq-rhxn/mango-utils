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
        WlrLayershell.namespace: "msnap-picker"

        WindowPicker {
            id: picker
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
            path: {
                const dir = Quickshell.env("XDG_RUNTIME_DIR") || Quickshell.env("TMPDIR") || "/tmp"
                return dir + "/msnap-picker-select"
            }
            blockWrites: true
            printErrors: false
        }
    }
}
