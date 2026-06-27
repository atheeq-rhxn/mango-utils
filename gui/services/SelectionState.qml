pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property real rectX: 0
    property real rectY: 0
    property real rectWidth: 0
    property real rectHeight: 0

    property bool isDrawing: false
    property bool isMoving: false
    property bool isResizing: false
    property int activeHandle: -1

    property real drawOriginX: 0
    property real drawOriginY: 0

    property real moveOriginX: 0
    property real moveOriginY: 0
    property real moveGrabX: 0
    property real moveGrabY: 0

    property real resizeAnchorX: 0
    property real resizeAnchorY: 0

    property bool isEditing: false

    readonly property int minimumSize: 4

    readonly property bool hasSelection: rectWidth > minimumSize && rectHeight > minimumSize

    function clear() {
        rectX = 0;
        rectY = 0;
        rectWidth = 0;
        rectHeight = 0;
        isEditing = false;
    }

    function cancelInteraction() {
        isDrawing = false;
        isMoving = false;
        isResizing = false;
        isEditing = false;
        activeHandle = -1;
    }

    function clampToScreen(screen) {
        if (!screen || rectWidth <= 0)
            return;
        const sf = screen.devicePixelRatio || 1.0;
        const sMinX = screen.x;
        const sMinY = screen.y;
        const sMaxX = sMinX + (screen.width * sf);
        const sMaxY = sMinY + (screen.height * sf);

        if (rectX < sMinX) {
            rectWidth = Math.max(0, rectWidth - (sMinX - rectX));
            rectX = sMinX;
        }
        if (rectX + rectWidth > sMaxX) {
            rectWidth = Math.max(0, sMaxX - rectX);
        }
        if (rectY < sMinY) {
            rectHeight = Math.max(0, rectHeight - (sMinY - rectY));
            rectY = sMinY;
        }
        if (rectY + rectHeight > sMaxY) {
            rectHeight = Math.max(0, sMaxY - rectY);
        }
        if (!hasSelection) {
            clear();
        }
    }
}
