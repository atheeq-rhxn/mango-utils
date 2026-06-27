pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import "services"

Item {
    id: root

    visible: CaptureState.captureArea === "region"

    property real scaleFactor: 1.0
    property real screenOffsetX: 0
    property real screenOffsetY: 0

    readonly property real localRectX: (SelectionState.rectX - screenOffsetX) / scaleFactor
    readonly property real localRectY: (SelectionState.rectY - screenOffsetY) / scaleFactor
    readonly property real localRectWidth: SelectionState.rectWidth / scaleFactor
    readonly property real localRectHeight: SelectionState.rectHeight / scaleFactor

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
        if (CaptureState.isShot)
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
            height: SelectionState.hasSelection ? Math.max(0, localRectY) : parent.height
            color: overlayColor
        }
        Rectangle {
            x: 0
            y: SelectionState.hasSelection ? Math.max(0, localRectY + localRectHeight) : parent.height
            width: parent.width
            height: SelectionState.hasSelection ? Math.max(0, parent.height - y) : 0
            color: overlayColor
        }
        Rectangle {
            x: 0
            y: Math.max(0, localRectY)
            width: SelectionState.hasSelection ? Math.max(0, localRectX) : 0
            height: SelectionState.hasSelection ? Math.max(0, Math.min(parent.height, localRectY + localRectHeight) - y) : 0
            color: overlayColor
        }
        Rectangle {
            x: SelectionState.hasSelection ? Math.max(0, localRectX + localRectWidth) : parent.width
            y: Math.max(0, localRectY)
            width: SelectionState.hasSelection ? Math.max(0, parent.width - x) : 0
            height: SelectionState.hasSelection ? Math.max(0, Math.min(parent.height, localRectY + localRectHeight) - y) : 0
            color: overlayColor
        }
    }

    Rectangle {
        x: localRectX
        y: localRectY
        width: localRectWidth
        height: localRectHeight
        visible: SelectionState.hasSelection
        color: "transparent"
        border.width: 2
        border.color: Config.ssAccent
        z: 5
    }

    Rectangle {
        visible: SelectionState.hasSelection
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
            text: Math.round(SelectionState.rectWidth) + " × " + Math.round(SelectionState.rectHeight) + " px"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Config.handleColor
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        text: SelectionState.hasSelection ? "Drag to move  ·  Corners to resize  ·  Enter to confirm  ·  Esc to cancel" : "Drag to select  ·  Esc to cancel"
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
            visible: SelectionState.hasSelection && !SelectionState.isDrawing
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
                    SelectionState.isResizing = true;
                    SelectionState.activeHandle = index;
                    const offset = resizeOffsets[index];
                    SelectionState.resizeAnchorX = SelectionState.rectX + offset.x * SelectionState.rectWidth;
                    SelectionState.resizeAnchorY = SelectionState.rectY + offset.y * SelectionState.rectHeight;
                    SelectionState.isEditing = true;
                }

                onPositionChanged: mouse => {
                    if (!SelectionState.isResizing || SelectionState.activeHandle !== index)
                        return;
                    const pt = mapToItem(root, mouse.x, mouse.y);
                    const clamped = clampToScreen((pt.x * scaleFactor) + screenOffsetX, (pt.y * scaleFactor) + screenOffsetY);
                    let ptGlobalX = clamped.x;
                    let ptGlobalY = clamped.y;

                    const ax = SelectionState.resizeAnchorX;
                    const ay = SelectionState.resizeAnchorY;

                    const nx = Math.min(ptGlobalX, ax);
                    const ny = Math.min(ptGlobalY, ay);
                    const nw = Math.abs(ptGlobalX - ax);
                    const nh = Math.abs(ptGlobalY - ay);

                    if (nw >= resizeMinimum && nh >= resizeMinimum) {
                        SelectionState.rectX = nx;
                        SelectionState.rectY = ny;
                        SelectionState.rectWidth = nw;
                        SelectionState.rectHeight = nh;
                    }
                }

                onReleased: {
                    SelectionState.isResizing = false;
                    SelectionState.activeHandle = -1;
                    SelectionState.isEditing = false;
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
            if (SelectionState.isDrawing)
                return Qt.CrossCursor;
            if (SelectionState.isMoving)
                return Qt.ClosedHandCursor;
            if (SelectionState.hasSelection && mouseX >= localRectX && mouseX <= localRectX + localRectWidth && mouseY >= localRectY && mouseY <= localRectY + localRectHeight) {
                return Qt.OpenHandCursor;
            }
            return Qt.CrossCursor;
        }

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (SelectionState.hasSelection) {
                    SelectionState.clear();
                } else {
                    CaptureService.closeAll();
                }
            }
        }

        onPressed: mouse => {
            if (mouse.button !== Qt.LeftButton || SelectionState.isResizing)
                return;
            const currentGlobal = clampToScreen((mouse.x * scaleFactor) + screenOffsetX, (mouse.y * scaleFactor) + screenOffsetY);

            const inSel = SelectionState.hasSelection && currentGlobal.x >= SelectionState.rectX && currentGlobal.x <= SelectionState.rectX + SelectionState.rectWidth && currentGlobal.y >= SelectionState.rectY && currentGlobal.y <= SelectionState.rectY + SelectionState.rectHeight;

            if (inSel) {
                SelectionState.isMoving = true;
                SelectionState.moveOriginX = SelectionState.rectX;
                SelectionState.moveOriginY = SelectionState.rectY;
                SelectionState.moveGrabX = currentGlobal.x;
                SelectionState.moveGrabY = currentGlobal.y;
                SelectionState.isEditing = true;
            } else {
                SelectionState.isDrawing = true;
                SelectionState.drawOriginX = currentGlobal.x;
                SelectionState.drawOriginY = currentGlobal.y;
                SelectionState.rectX = currentGlobal.x;
                SelectionState.rectY = currentGlobal.y;
                SelectionState.rectWidth = 0;
                SelectionState.rectHeight = 0;
                SelectionState.isEditing = true;
            }
        }

        onPositionChanged: mouse => {
            const currentGlobal = clampToScreen((mouse.x * scaleFactor) + screenOffsetX, (mouse.y * scaleFactor) + screenOffsetY);
            let currentGlobalX = currentGlobal.x;
            let currentGlobalY = currentGlobal.y;

            if (SelectionState.isDrawing) {
                SelectionState.rectX = Math.min(currentGlobalX, SelectionState.drawOriginX);
                SelectionState.rectY = Math.min(currentGlobalY, SelectionState.drawOriginY);
                SelectionState.rectWidth = Math.abs(currentGlobalX - SelectionState.drawOriginX);
                SelectionState.rectHeight = Math.abs(currentGlobalY - SelectionState.drawOriginY);
                return;
            }

            if (SelectionState.isMoving) {
                const dx = currentGlobalX - SelectionState.moveGrabX;
                const dy = currentGlobalY - SelectionState.moveGrabY;

                if (!CaptureState.isShot) {
                    const maxX = screenOffsetX + (root.width * scaleFactor) - SelectionState.rectWidth;
                    const maxY = screenOffsetY + (root.height * scaleFactor) - SelectionState.rectHeight;
                    SelectionState.rectX = Math.max(screenOffsetX, Math.min(SelectionState.moveOriginX + dx, maxX));
                    SelectionState.rectY = Math.max(screenOffsetY, Math.min(SelectionState.moveOriginY + dy, maxY));
                } else {
                    SelectionState.rectX = SelectionState.moveOriginX + dx;
                    SelectionState.rectY = SelectionState.moveOriginY + dy;
                }
            }
        }

        onReleased: mouse => {
            if (mouse.button === Qt.LeftButton) {
                SelectionState.isDrawing = false;
                SelectionState.isMoving = false;
                SelectionState.isEditing = false;
            }
        }
    }
}
