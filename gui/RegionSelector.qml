import QtQuick
import QtQuick.Window

Item {
    id: selectorRoot
    anchors.fill: parent
    visible: globalState.captureMode === "region"

    property real scaleFactor: 1.0
    property real screenOffsetX: 0
    property real screenOffsetY: 0

    readonly property real localSelX: (globalState.globalSelX - screenOffsetX) / scaleFactor
    readonly property real localSelY: (globalState.globalSelY - screenOffsetY) / scaleFactor
    readonly property real localSelW: globalState.globalSelW / scaleFactor
    readonly property real localSelH: globalState.globalSelH / scaleFactor
    
    readonly property bool hasSelection: globalState.globalSelW > 4 && globalState.globalSelH > 4

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

    // Background Dimming Handles (Calculated strictly to allow negative/cross-monitor clipping)
    Item {
        anchors.fill: parent
        visible: selectorRoot.visible

        Rectangle { // Top
            x: 0; y: 0; width: parent.width
            height: hasSelection ? Math.max(0, selectorRoot.localSelY) : parent.height
            color: selectorRoot.overlayMask
        }
        Rectangle { // Bottom
            x: 0; y: hasSelection ? Math.max(0, selectorRoot.localSelY + selectorRoot.localSelH) : parent.height
            width: parent.width
            height: hasSelection ? Math.max(0, parent.height - y) : 0
            color: selectorRoot.overlayMask
        }
        Rectangle { // Left
            x: 0; y: Math.max(0, selectorRoot.localSelY)
            width: hasSelection ? Math.max(0, selectorRoot.localSelX) : 0
            height: hasSelection ? Math.max(0, Math.min(parent.height, selectorRoot.localSelY + selectorRoot.localSelH) - y) : 0
            color: selectorRoot.overlayMask
        }
        Rectangle { // Right
            x: hasSelection ? Math.max(0, selectorRoot.localSelX + selectorRoot.localSelW) : parent.width
            y: Math.max(0, selectorRoot.localSelY)
            width: hasSelection ? Math.max(0, parent.width - x) : 0
            height: hasSelection ? Math.max(0, Math.min(parent.height, selectorRoot.localSelY + selectorRoot.localSelH) - y) : 0
            color: selectorRoot.overlayMask
        }
    }

    // The Stroke Box
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

    // Dimension Label
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
            text: Math.round(globalState.globalSelW) + " × " + Math.round(globalState.globalSelH) + " px"
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

    // Resize Handles
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
            visible: selectorRoot.hasSelection && !globalState.isSelecting
            color: Config.handleColor
            border.width: 2
            border.color: Config.ssAccent
            z: 12

            MouseArea {
                anchors { fill: parent; margins: -selectorRoot.handleHitArea }
                cursorShape: modelData.cursor
                hoverEnabled: true

                onPressed: mouse => {
                    globalState.isResizing = true
                    globalState.activeHandle = index
                    const offset = selectorRoot.anchorOffsets[index]
                    globalState.resizeAnchorX = globalState.globalSelX + offset.x * globalState.globalSelW
                    globalState.resizeAnchorY = globalState.globalSelY + offset.y * globalState.globalSelH
                    globalState.isActivelyEditing = true
                }

                onPositionChanged: mouse => {
                    if (!globalState.isResizing || globalState.activeHandle !== index) return
             
                    const pt = mapToItem(selectorRoot, mouse.x, mouse.y)
                    const ptGlobalX = (pt.x * selectorRoot.scaleFactor) + selectorRoot.screenOffsetX
                    const ptGlobalY = (pt.y * selectorRoot.scaleFactor) + selectorRoot.screenOffsetY
                    
                    const ax = globalState.resizeAnchorX
                    const ay = globalState.resizeAnchorY

                    const nx = Math.min(ptGlobalX, ax)
                    const ny = Math.min(ptGlobalY, ay)
                    const nw = Math.abs(ptGlobalX - ax)
                    const nh = Math.abs(ptGlobalY - ay)

                    if (nw >= selectorRoot.minSelectionSize && nh >= selectorRoot.minSelectionSize) {
                        globalState.globalSelX = nx
                        globalState.globalSelY = ny
                        globalState.globalSelW = nw
                        globalState.globalSelH = nh
                    }
                }

                onReleased: {
                    globalState.isResizing = false
                    globalState.activeHandle = -1
                    globalState.isActivelyEditing = false
                }
            }
        }
    }

    // Main Selection Field
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        z: 3

        cursorShape: {
            if (globalState.isSelecting) return Qt.CrossCursor
            if (globalState.isMoving) return Qt.ClosedHandCursor
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
                    globalState.globalSelW = 0
                    globalState.globalSelH = 0
                    globalState.isActivelyEditing = false
                } else {
                    globalState.closeAll()
                }
            }
        }

        onPressed: mouse => {
            if (mouse.button !== Qt.LeftButton || globalState.isResizing) return
            
            const currentGlobalX = (mouse.x * selectorRoot.scaleFactor) + selectorRoot.screenOffsetX
            const currentGlobalY = (mouse.y * selectorRoot.scaleFactor) + selectorRoot.screenOffsetY

            const inSel = selectorRoot.hasSelection && 
                          currentGlobalX >= globalState.globalSelX && 
                          currentGlobalX <= globalState.globalSelX + globalState.globalSelW && 
                          currentGlobalY >= globalState.globalSelY && 
                          currentGlobalY <= globalState.globalSelY + globalState.globalSelH
            
            if (inSel) {
                globalState.isMoving = true
                globalState.moveStartSelX = globalState.globalSelX
                globalState.moveStartSelY = globalState.globalSelY
                globalState.moveStartMouseX = currentGlobalX
                globalState.moveStartMouseY = currentGlobalY
                globalState.isActivelyEditing = true
            } else {
                globalState.isSelecting = true
                globalState.startX = currentGlobalX
                globalState.startY = currentGlobalY
                globalState.globalSelX = currentGlobalX
                globalState.globalSelY = currentGlobalY
                globalState.globalSelW = 0
                globalState.globalSelH = 0
                globalState.isActivelyEditing = true
            }
        }

        onPositionChanged: mouse => {
            const currentGlobalX = (mouse.x * selectorRoot.scaleFactor) + selectorRoot.screenOffsetX
            const currentGlobalY = (mouse.y * selectorRoot.scaleFactor) + selectorRoot.screenOffsetY

            if (globalState.isSelecting) {
                globalState.globalSelX = Math.min(currentGlobalX, globalState.startX)
                globalState.globalSelY = Math.min(currentGlobalY, globalState.startY)
                globalState.globalSelW = Math.abs(currentGlobalX - globalState.startX)
                globalState.globalSelH = Math.abs(currentGlobalY - globalState.startY)
                return
            }

            if (globalState.isMoving) {
                const dx = currentGlobalX - globalState.moveStartMouseX
                const dy = currentGlobalY - globalState.moveStartMouseY
                const maxX = selectorRoot.screenOffsetX + (selectorRoot.width * selectorRoot.scaleFactor) - globalState.globalSelW
                const maxY = selectorRoot.screenOffsetY + (selectorRoot.height * selectorRoot.scaleFactor) - globalState.globalSelH
                globalState.globalSelX = Math.max(selectorRoot.screenOffsetX, Math.min(globalState.moveStartSelX + dx, maxX))
                globalState.globalSelY = Math.max(selectorRoot.screenOffsetY, Math.min(globalState.moveStartSelY + dy, maxY))
            }
        }

        onReleased: mouse => {
            if (mouse.button === Qt.LeftButton) {
                globalState.isSelecting = false
                globalState.isMoving = false
                globalState.isActivelyEditing = false
            }
        }
    }
}
