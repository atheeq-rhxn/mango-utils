pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window

Item {
    id: selectorRoot
    anchors.fill: parent
    visible: globalState.captureMode === "region"

    property real scaleFactor: 1.0
    property real screenOffsetX: 0
    property real screenOffsetY: 0

    readonly property real localSelX: (selectionState.globalSelX - screenOffsetX) / scaleFactor
    readonly property real localSelY: (selectionState.globalSelY - screenOffsetY) / scaleFactor
    readonly property real localSelW: selectionState.globalSelW / scaleFactor
    readonly property real localSelH: selectionState.globalSelH / scaleFactor

    readonly property bool hasSelection: selectionState.globalSelW > selectionState.minSelectionSize && selectionState.globalSelH > selectionState.minSelectionSize

    readonly property color overlayMask: Qt.rgba(Config.overlayColor.r, Config.overlayColor.g, Config.overlayColor.b, Config.overlayAlpha)
    readonly property color dimLabelBg: Qt.rgba(Config.dimLabelBg.r, Config.dimLabelBg.g, Config.dimLabelBg.b, Config.dimLabelAlpha)
    readonly property color instructionTextColor: Qt.rgba(Config.instructionColor.r, Config.instructionColor.g, Config.instructionColor.b, Config.instructionAlpha)

    readonly property var handlePositions: [
        { x: 0, y: 0, cursor: Qt.SizeFDiagCursor },
        { x: 1, y: 0, cursor: Qt.SizeBDiagCursor },
        { x: 0, y: 1, cursor: Qt.SizeBDiagCursor },
        { x: 1, y: 1, cursor: Qt.SizeFDiagCursor }
    ]

    readonly property var anchorOffsets: [
        { x: 1, y: 1 },
        { x: 0, y: 1 },
        { x: 1, y: 0 },
        { x: 0, y: 0 }
    ]

    readonly property int handleSize: 12
    readonly property int handleHitArea: 8
    readonly property int minSelectionSize: 8

    function clampToScreen(globalX, globalY) {
        if (globalState.isShot) return { x: globalX, y: globalY }
        const screenMaxX = screenOffsetX + (width * scaleFactor)
        const screenMaxY = screenOffsetY + (height * scaleFactor)
        return {
            x: Math.max(screenOffsetX, Math.min(globalX, screenMaxX)),
            y: Math.max(screenOffsetY, Math.min(globalY, screenMaxY))
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            x: 0; y: 0; width: parent.width
            height: selectorRoot.hasSelection ? Math.max(0, selectorRoot.localSelY) : parent.height
            color: selectorRoot.overlayMask
        }
        Rectangle {
            x: 0; y: selectorRoot.hasSelection ? Math.max(0, selectorRoot.localSelY + selectorRoot.localSelH) : parent.height
            width: parent.width
            height: selectorRoot.hasSelection ? Math.max(0, parent.height - y) : 0
            color: selectorRoot.overlayMask
        }
        Rectangle {
            x: 0; y: Math.max(0, selectorRoot.localSelY)
            width: selectorRoot.hasSelection ? Math.max(0, selectorRoot.localSelX) : 0
            height: selectorRoot.hasSelection ? Math.max(0, Math.min(parent.height, selectorRoot.localSelY + selectorRoot.localSelH) - y) : 0
            color: selectorRoot.overlayMask
        }
        Rectangle {
            x: selectorRoot.hasSelection ? Math.max(0, selectorRoot.localSelX + selectorRoot.localSelW) : parent.width
            y: Math.max(0, selectorRoot.localSelY)
            width: selectorRoot.hasSelection ? Math.max(0, parent.width - x) : 0
            height: selectorRoot.hasSelection ? Math.max(0, Math.min(parent.height, selectorRoot.localSelY + selectorRoot.localSelH) - y) : 0
            color: selectorRoot.overlayMask
        }
    }

    Rectangle {
        x: selectorRoot.localSelX
        y: selectorRoot.localSelY
        width: selectorRoot.localSelW
        height: selectorRoot.localSelH
        visible: selectorRoot.hasSelection
        color: "transparent"
        border.width: 2
        border.color: Config.ssAccent
        z: 5
    }

    Rectangle {
        visible: selectorRoot.hasSelection
        x: Math.min(Math.max(selectorRoot.localSelX + 8, 8), parent.width - width - 8)
        y: selectorRoot.localSelY > 38 ? selectorRoot.localSelY - 32 : selectorRoot.localSelY + selectorRoot.localSelH + 8
        width: dimText.implicitWidth + 16
        height: 24
        radius: 12
        color: selectorRoot.dimLabelBg
        z: 10

        Text {
            id: dimText
            anchors.centerIn: parent
            text: Math.round(selectionState.globalSelW) + " × " + Math.round(selectionState.globalSelH) + " px"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Config.handleColor
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        text: selectorRoot.hasSelection ? "Drag to move  ·  Corners to resize  ·  Enter to confirm  ·  Esc to cancel" : "Drag to select  ·  Esc to cancel"
        font.pixelSize: 11
        color: selectorRoot.instructionTextColor
        z: 10
    }

    Repeater {
        model: selectorRoot.handlePositions

        delegate: Rectangle {
            required property var modelData
            required property int index

            readonly property int hx: modelData.x === 0 ? selectorRoot.localSelX : selectorRoot.localSelX + selectorRoot.localSelW
            readonly property int hy: modelData.y === 0 ? selectorRoot.localSelY : selectorRoot.localSelY + selectorRoot.localSelH

            x: hx - selectorRoot.handleSize / 2
            y: hy - selectorRoot.handleSize / 2
            width: selectorRoot.handleSize
            height: selectorRoot.handleSize
            radius: selectorRoot.handleSize / 2
            visible: selectorRoot.hasSelection && !selectionState.isSelecting
            color: Config.handleColor
            border.width: 2
            border.color: Config.ssAccent
            z: 12

            MouseArea {
                anchors { fill: parent; margins: -selectorRoot.handleHitArea }
                cursorShape: modelData.cursor
                hoverEnabled: true

                onPressed: mouse => {
                    selectionState.isResizing = true
                    selectionState.activeHandle = index
                    const offset = selectorRoot.anchorOffsets[index]
                    selectionState.resizeAnchorX = selectionState.globalSelX + offset.x * selectionState.globalSelW
                    selectionState.resizeAnchorY = selectionState.globalSelY + offset.y * selectionState.globalSelH
                    selectionState.isActivelyEditing = true
                }

                onPositionChanged: mouse => {
                    if (!selectionState.isResizing || selectionState.activeHandle !== index) return

                    const pt = mapToItem(selectorRoot, mouse.x, mouse.y)
                    const clamped = selectorRoot.clampToScreen(
                        (pt.x * selectorRoot.scaleFactor) + selectorRoot.screenOffsetX,
                        (pt.y * selectorRoot.scaleFactor) + selectorRoot.screenOffsetY
                    )
                    let ptGlobalX = clamped.x
                    let ptGlobalY = clamped.y

                    const ax = selectionState.resizeAnchorX
                    const ay = selectionState.resizeAnchorY

                    const nx = Math.min(ptGlobalX, ax)
                    const ny = Math.min(ptGlobalY, ay)
                    const nw = Math.abs(ptGlobalX - ax)
                    const nh = Math.abs(ptGlobalY - ay)

                    if (nw >= selectorRoot.minSelectionSize && nh >= selectorRoot.minSelectionSize) {
                        selectionState.globalSelX = nx
                        selectionState.globalSelY = ny
                        selectionState.globalSelW = nw
                        selectionState.globalSelH = nh
                    }
                }

                onReleased: {
                    selectionState.isResizing = false
                    selectionState.activeHandle = -1
                    selectionState.isActivelyEditing = false
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
            if (selectionState.isSelecting) return Qt.CrossCursor
            if (selectionState.isMoving) return Qt.ClosedHandCursor
            if (selectorRoot.hasSelection &&
                mouseX >= selectorRoot.localSelX &&
                mouseX <= selectorRoot.localSelX + selectorRoot.localSelW &&
                mouseY >= selectorRoot.localSelY &&
                mouseY <= selectorRoot.localSelY + selectorRoot.localSelH) {
                return Qt.OpenHandCursor
            }
            return Qt.CrossCursor
        }

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (selectorRoot.hasSelection) {
                    selectionState.clearSelection()
                } else {
                    globalState.closeAll()
                }
            }
        }

        onPressed: mouse => {
            if (mouse.button !== Qt.LeftButton || selectionState.isResizing) return

            const currentGlobal = selectorRoot.clampToScreen(
                (mouse.x * selectorRoot.scaleFactor) + selectorRoot.screenOffsetX,
                (mouse.y * selectorRoot.scaleFactor) + selectorRoot.screenOffsetY
            )

            const inSel = selectorRoot.hasSelection &&
                          currentGlobal.x >= selectionState.globalSelX &&
                          currentGlobal.x <= selectionState.globalSelX + selectionState.globalSelW &&
                          currentGlobal.y >= selectionState.globalSelY &&
                          currentGlobal.y <= selectionState.globalSelY + selectionState.globalSelH

            if (inSel) {
                selectionState.isMoving = true
                selectionState.moveStartSelX = selectionState.globalSelX
                selectionState.moveStartSelY = selectionState.globalSelY
                selectionState.moveStartMouseX = currentGlobal.x
                selectionState.moveStartMouseY = currentGlobal.y
                selectionState.isActivelyEditing = true
            } else {
                selectionState.isSelecting = true
                selectionState.startX = currentGlobal.x
                selectionState.startY = currentGlobal.y
                selectionState.globalSelX = currentGlobal.x
                selectionState.globalSelY = currentGlobal.y
                selectionState.globalSelW = 0
                selectionState.globalSelH = 0
                selectionState.isActivelyEditing = true
            }
        }

        onPositionChanged: mouse => {
            const currentGlobal = selectorRoot.clampToScreen(
                (mouse.x * selectorRoot.scaleFactor) + selectorRoot.screenOffsetX,
                (mouse.y * selectorRoot.scaleFactor) + selectorRoot.screenOffsetY
            )
            let currentGlobalX = currentGlobal.x
            let currentGlobalY = currentGlobal.y

            if (selectionState.isSelecting) {
                selectionState.globalSelX = Math.min(currentGlobalX, selectionState.startX)
                selectionState.globalSelY = Math.min(currentGlobalY, selectionState.startY)
                selectionState.globalSelW = Math.abs(currentGlobalX - selectionState.startX)
                selectionState.globalSelH = Math.abs(currentGlobalY - selectionState.startY)
                return
            }

            if (selectionState.isMoving) {
                const dx = currentGlobalX - selectionState.moveStartMouseX
                const dy = currentGlobalY - selectionState.moveStartMouseY

                if (!globalState.isShot) {
                    const maxX = selectorRoot.screenOffsetX + (selectorRoot.width * selectorRoot.scaleFactor) - selectionState.globalSelW
                    const maxY = selectorRoot.screenOffsetY + (selectorRoot.height * selectorRoot.scaleFactor) - selectionState.globalSelH
                    selectionState.globalSelX = Math.max(selectorRoot.screenOffsetX, Math.min(selectionState.moveStartSelX + dx, maxX))
                    selectionState.globalSelY = Math.max(selectorRoot.screenOffsetY, Math.min(selectionState.moveStartSelY + dy, maxY))
                } else {
                    selectionState.globalSelX = selectionState.moveStartSelX + dx
                    selectionState.globalSelY = selectionState.moveStartSelY + dy
                }
            }
        }

        onReleased: mouse => {
            if (mouse.button === Qt.LeftButton) {
                selectionState.isSelecting = false
                selectionState.isMoving = false
                selectionState.isActivelyEditing = false
            }
        }
    }
}
