pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window

Item {
    id: root

    visible: globalState.captureMode === "region"

    property real scaleFactor: 1.0
    property real screenOffsetX: 0
    property real screenOffsetY: 0

    readonly property real localRectX: (selectionState.rectX - screenOffsetX) / scaleFactor
    readonly property real localRectY: (selectionState.rectY - screenOffsetY) / scaleFactor
    readonly property real localRectWidth: selectionState.rectWidth / scaleFactor
    readonly property real localRectHeight: selectionState.rectHeight / scaleFactor

    readonly property color overlayColor: Qt.rgba(Config.overlayColor.r, Config.overlayColor.g, Config.overlayColor.b, Config.overlayAlpha)
    readonly property color dimLabelColor: Qt.rgba(Config.dimLabelBg.r, Config.dimLabelBg.g, Config.dimLabelBg.b, Config.dimLabelAlpha)
    readonly property color instructionColor: Qt.rgba(Config.instructionColor.r, Config.instructionColor.g, Config.instructionColor.b, Config.instructionAlpha)

    readonly property var handleAnchors: [
        {
            x: 0,
            y: 0,
            cursor: Qt.SizeFDiagCursor
        },
        {
            x: 1,
            y: 0,
            cursor: Qt.SizeBDiagCursor
        },
        {
            x: 0,
            y: 1,
            cursor: Qt.SizeBDiagCursor
        },
        {
            x: 1,
            y: 1,
            cursor: Qt.SizeFDiagCursor
        }
    ]

    readonly property var resizeOffsets: [
        {
            x: 1,
            y: 1
        },
        {
            x: 0,
            y: 1
        },
        {
            x: 1,
            y: 0
        },
        {
            x: 0,
            y: 0
        }
    ]

    readonly property int handleSize: 12
    readonly property int handleHitMargin: 8
    readonly property int resizeMinimum: 8

    function clampToScreen(globalX, globalY) {
        if (globalState.isShot)
            return {
                x: globalX,
                y: globalY
            };
        const screenMaxX = screenOffsetX + (width * scaleFactor);
        const screenMaxY = screenOffsetY + (height * scaleFactor);
        return {
            x: Math.max(screenOffsetX, Math.min(globalX, screenMaxX)),
            y: Math.max(screenOffsetY, Math.min(globalY, screenMaxY))
        };
    }

    Item {
        anchors.fill: parent

        Rectangle {
            x: 0
            y: 0
            width: parent.width
            height: selectionState.hasSelection ? Math.max(0, localRectY) : parent.height
            color: overlayColor
        }
        Rectangle {
            x: 0
            y: selectionState.hasSelection ? Math.max(0, localRectY + localRectHeight) : parent.height
            width: parent.width
            height: selectionState.hasSelection ? Math.max(0, parent.height - y) : 0
            color: overlayColor
        }
        Rectangle {
            x: 0
            y: Math.max(0, localRectY)
            width: selectionState.hasSelection ? Math.max(0, localRectX) : 0
            height: selectionState.hasSelection ? Math.max(0, Math.min(parent.height, localRectY + localRectHeight) - y) : 0
            color: overlayColor
        }
        Rectangle {
            x: selectionState.hasSelection ? Math.max(0, localRectX + localRectWidth) : parent.width
            y: Math.max(0, localRectY)
            width: selectionState.hasSelection ? Math.max(0, parent.width - x) : 0
            height: selectionState.hasSelection ? Math.max(0, Math.min(parent.height, localRectY + localRectHeight) - y) : 0
            color: overlayColor
        }
    }

    Rectangle {
        x: localRectX
        y: localRectY
        width: localRectWidth
        height: localRectHeight
        visible: selectionState.hasSelection
        color: "transparent"
        border.width: 2
        border.color: Config.ssAccent
        z: 5
    }

    Rectangle {
        visible: selectionState.hasSelection
        x: Math.min(Math.max(localRectX + 8, 8), parent.width - width - 8)
        y: localRectY > 38 ? localRectY - 32 : localRectY + localRectHeight + 8
        width: dimText.implicitWidth + 16
        height: 24
        radius: 12
        color: dimLabelColor
        z: 10

        Text {
            id: dimText
            anchors.centerIn: parent
            text: Math.round(selectionState.rectWidth) + " × " + Math.round(selectionState.rectHeight) + " px"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Config.handleColor
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        text: selectionState.hasSelection ? "Drag to move  ·  Corners to resize  ·  Enter to confirm  ·  Esc to cancel" : "Drag to select  ·  Esc to cancel"
        font.pixelSize: 11
        color: instructionColor
        z: 10
    }

    Repeater {
        model: handleAnchors

        delegate: Rectangle {
            required property var modelData
            required property int index

            readonly property int hx: modelData.x === 0 ? localRectX : localRectX + localRectWidth
            readonly property int hy: modelData.y === 0 ? localRectY : localRectY + localRectHeight

            x: hx - handleSize / 2
            y: hy - handleSize / 2
            width: handleSize
            height: handleSize
            radius: handleSize / 2
            visible: selectionState.hasSelection && !selectionState.isDrawing
            color: Config.handleColor
            border.width: 2
            border.color: Config.ssAccent
            z: 12

            MouseArea {
                anchors {
                    fill: parent
                    margins: -handleHitMargin
                }
                cursorShape: modelData.cursor
                hoverEnabled: true

                onPressed: mouse => {
                    selectionState.isResizing = true;
                    selectionState.activeHandle = index;
                    const offset = resizeOffsets[index];
                    selectionState.resizeAnchorX = selectionState.rectX + offset.x * selectionState.rectWidth;
                    selectionState.resizeAnchorY = selectionState.rectY + offset.y * selectionState.rectHeight;
                    selectionState.isEditing = true;
                }

                onPositionChanged: mouse => {
                    if (!selectionState.isResizing || selectionState.activeHandle !== index)
                        return;
                    const pt = mapToItem(root, mouse.x, mouse.y);
                    const clamped = clampToScreen((pt.x * scaleFactor) + screenOffsetX, (pt.y * scaleFactor) + screenOffsetY);
                    let ptGlobalX = clamped.x;
                    let ptGlobalY = clamped.y;

                    const ax = selectionState.resizeAnchorX;
                    const ay = selectionState.resizeAnchorY;

                    const nx = Math.min(ptGlobalX, ax);
                    const ny = Math.min(ptGlobalY, ay);
                    const nw = Math.abs(ptGlobalX - ax);
                    const nh = Math.abs(ptGlobalY - ay);

                    if (nw >= resizeMinimum && nh >= resizeMinimum) {
                        selectionState.rectX = nx;
                        selectionState.rectY = ny;
                        selectionState.rectWidth = nw;
                        selectionState.rectHeight = nh;
                    }
                }

                onReleased: {
                    selectionState.isResizing = false;
                    selectionState.activeHandle = -1;
                    selectionState.isEditing = false;
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        z: 3

        cursorShape: {
            if (selectionState.isDrawing)
                return Qt.CrossCursor;
            if (selectionState.isMoving)
                return Qt.ClosedHandCursor;
            if (selectionState.hasSelection && mouseX >= localRectX && mouseX <= localRectX + localRectWidth && mouseY >= localRectY && mouseY <= localRectY + localRectHeight) {
                return Qt.OpenHandCursor;
            }
            return Qt.CrossCursor;
        }

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (selectionState.hasSelection) {
                    selectionState.clear();
                } else {
                    globalState.closeAll();
                }
            }
        }

        onPressed: mouse => {
            if (mouse.button !== Qt.LeftButton || selectionState.isResizing)
                return;
            const currentGlobal = clampToScreen((mouse.x * scaleFactor) + screenOffsetX, (mouse.y * scaleFactor) + screenOffsetY);

            const inSel = selectionState.hasSelection && currentGlobal.x >= selectionState.rectX && currentGlobal.x <= selectionState.rectX + selectionState.rectWidth && currentGlobal.y >= selectionState.rectY && currentGlobal.y <= selectionState.rectY + selectionState.rectHeight;

            if (inSel) {
                selectionState.isMoving = true;
                selectionState.moveOriginX = selectionState.rectX;
                selectionState.moveOriginY = selectionState.rectY;
                selectionState.moveGrabX = currentGlobal.x;
                selectionState.moveGrabY = currentGlobal.y;
                selectionState.isEditing = true;
            } else {
                selectionState.isDrawing = true;
                selectionState.drawOriginX = currentGlobal.x;
                selectionState.drawOriginY = currentGlobal.y;
                selectionState.rectX = currentGlobal.x;
                selectionState.rectY = currentGlobal.y;
                selectionState.rectWidth = 0;
                selectionState.rectHeight = 0;
                selectionState.isEditing = true;
            }
        }

        onPositionChanged: mouse => {
            const currentGlobal = clampToScreen((mouse.x * scaleFactor) + screenOffsetX, (mouse.y * scaleFactor) + screenOffsetY);
            let currentGlobalX = currentGlobal.x;
            let currentGlobalY = currentGlobal.y;

            if (selectionState.isDrawing) {
                selectionState.rectX = Math.min(currentGlobalX, selectionState.drawOriginX);
                selectionState.rectY = Math.min(currentGlobalY, selectionState.drawOriginY);
                selectionState.rectWidth = Math.abs(currentGlobalX - selectionState.drawOriginX);
                selectionState.rectHeight = Math.abs(currentGlobalY - selectionState.drawOriginY);
                return;
            }

            if (selectionState.isMoving) {
                const dx = currentGlobalX - selectionState.moveGrabX;
                const dy = currentGlobalY - selectionState.moveGrabY;

                if (!globalState.isShot) {
                    const maxX = screenOffsetX + (root.width * scaleFactor) - selectionState.rectWidth;
                    const maxY = screenOffsetY + (root.height * scaleFactor) - selectionState.rectHeight;
                    selectionState.rectX = Math.max(screenOffsetX, Math.min(selectionState.moveOriginX + dx, maxX));
                    selectionState.rectY = Math.max(screenOffsetY, Math.min(selectionState.moveOriginY + dy, maxY));
                } else {
                    selectionState.rectX = selectionState.moveOriginX + dx;
                    selectionState.rectY = selectionState.moveOriginY + dy;
                }
            }
        }

        onReleased: mouse => {
            if (mouse.button === Qt.LeftButton) {
                selectionState.isDrawing = false;
                selectionState.isMoving = false;
                selectionState.isEditing = false;
            }
        }
    }
}
