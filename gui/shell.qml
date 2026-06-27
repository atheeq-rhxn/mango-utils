pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "components"
import "services"

Scope {

    Component.onCompleted: {
        CaptureService.isLoaded = true;
        if (CaptureState.isShot)
            FreezeState.enter();
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: windowRoot
            required property var modelData
            screen: modelData

            anchors.top: true
            anchors.left: true
            anchors.right: true
            anchors.bottom: true
            visible: CaptureService.windowsVisible
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "msnap-overlay"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            Item {
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()
                onVisibleChanged: if (visible)
                    forceActiveFocus()

                function cycleTarget(dir) {
                    const modes = CaptureState.isShot ? ["region", "window", "screen"] : ["region", "screen"];
                    const i = modes.indexOf(CaptureState.captureArea);
                    CaptureState.captureArea = modes[((i < 0 ? 0 : i) + dir + modes.length) % modes.length];
                }

                Keys.onTabPressed: CaptureState.isShot = !CaptureState.isShot
                Keys.onBacktabPressed: CaptureState.isShot = !CaptureState.isShot
                Keys.onReturnPressed: CaptureService.executeAction()
                Keys.onEnterPressed: CaptureService.executeAction()
                Keys.onSpacePressed: CaptureService.executeAction()
                Keys.onEscapePressed: {
                    if (CaptureState.captureArea === "region" && SelectionState.rectWidth > SelectionState.minimumSize) {
                        SelectionState.clear();
                    } else {
                        CaptureService.closeAll();
                    }
                }

                readonly property var keyHandlers: ({
                        [Qt.Key_H]: () => cycleTarget(-1),
                        [Qt.Key_J]: () => {
                            CaptureState.isShot = !CaptureState.isShot;
                        },
                        [Qt.Key_K]: () => {
                            CaptureState.isShot = !CaptureState.isShot;
                        },
                        [Qt.Key_L]: () => cycleTarget(1),
                        [Qt.Key_Left]: () => cycleTarget(-1),
                        [Qt.Key_Right]: () => cycleTarget(1),
                        [Qt.Key_S]: () => {
                            CaptureState.isShot = true;
                        },
                        [Qt.Key_V]: () => {
                            CaptureState.isShot = false;
                        },
                        [Qt.Key_R]: () => {
                            CaptureState.captureArea = "region";
                        },
                        [Qt.Key_W]: () => {
                            if (CaptureState.isShot)
                                CaptureState.captureArea = "window";
                        },
                        [Qt.Key_F]: () => {
                            CaptureState.captureArea = "screen";
                        },
                        [Qt.Key_P]: () => {
                            if (CaptureState.isShot)
                                CaptureState.pointer = !CaptureState.pointer;
                        },
                        [Qt.Key_E]: () => {
                            if (CaptureState.isShot)
                                CaptureState.annotate = !CaptureState.annotate;
                        },
                        [Qt.Key_M]: () => {
                            if (!CaptureState.isShot)
                                CaptureState.mic = !CaptureState.mic;
                        },
                        [Qt.Key_A]: () => {
                            if (!CaptureState.isShot)
                                CaptureState.audio = !CaptureState.audio;
                        }
                    })

                Keys.onPressed: event => {
                    const fn = keyHandlers[event.key];
                    if (fn) {
                        fn();
                        event.accepted = true;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    enabled: CaptureState.captureArea !== "region"
                    onClicked: CaptureService.closeAll()
                    z: 0
                }

                HoverHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onPointChanged: CaptureService.activeScreen = windowRoot.modelData
                }

                RegionSelector {
                    id: regionSelector
                    anchors.fill: parent
                    z: 1
                    scaleFactor: windowRoot.screen ? windowRoot.screen.devicePixelRatio : 1.0
                    screenOffsetX: windowRoot.screen.x
                    screenOffsetY: windowRoot.screen.y
                }

                Item {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 160
                    z: 10

                    Rectangle {
                        visible: CastState.showCastAlert
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 40
                        width: toastRow.implicitWidth + 24
                        height: 44
                        radius: 22
                        color: CaptureState.pillBackground
                        border.color: Config.recAccent
                        border.width: 1
                        opacity: CastState.showCastAlert ? 1.0 : 0.0
                        z: 10
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }

                        RowLayout {
                            id: toastRow
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                implicitWidth: 8
                                implicitHeight: 8
                                radius: 4
                                color: Config.recAccent
                                SequentialAnimation on opacity {
                                    running: CastState.showCastAlert
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        to: 0.3
                                        duration: 700
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        to: 1.0
                                        duration: 700
                                        easing.type: Easing.InOutSine
                                    }
                                }
                            }

                            Text {
                                text: "Recording in progress"
                                color: Config.textColor
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                        }
                    }

                    Rectangle {
                        id: pullTab
                        visible: !CastState.showCastAlert && !CastState.isTransitioningToCast && CaptureState.captureArea === "region"
                        z: 11
                        width: 48
                        height: 24
                        radius: 12
                        color: CaptureState.pillBackground
                        border.color: Config.borderColor
                        border.width: 1

                        x: (parent.width - width) / 2
                        y: SelectionState.isEditing ? parent.height + 10 : (CaptureState.toolbarCollapsed ? parent.height - 24 : parent.height - toolbar.idleH - 40 - height + 12)

                        Behavior on y {
                            enabled: CaptureService.isLoaded
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }

                        Icon {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: CaptureState.toolbarCollapsed ? 0 : -2
                            name: CaptureState.toolbarCollapsed ? "chevron-up" : "chevron-down"
                            size: 16
                            color: Config.textMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: CaptureState.toolbarCollapsed = !CaptureState.toolbarCollapsed
                        }
                    }

                    Rectangle {
                        id: toolbar
                        visible: !CastState.showCastAlert
                        clip: true
                        z: 10

                        readonly property real idleW: mainRow.implicitWidth + 32
                        readonly property real idleH: 56

                        x: CastState.isTransitioningToCast ? parent.width - 6 - 12 : (parent.width - width) / 2
                        width: CastState.isTransitioningToCast ? 6 : idleW
                        height: CastState.isTransitioningToCast ? 44 : idleH
                        radius: CastState.isTransitioningToCast ? 3 : idleH / 2

                        y: SelectionState.isEditing ? parent.height + 10 : (CaptureState.toolbarCollapsed && CaptureState.captureArea === "region" ? parent.height + 10 : parent.height - idleH - 40)

                        color: CaptureState.pillBackground
                        border.color: CastState.isTransitioningToCast ? Config.recAccent : Config.borderColor
                        border.width: 1
                        opacity: CastState.isTransitioningToCast ? 0.0 : (SelectionState.isEditing ? 0.0 : 1.0)

                        Behavior on y {
                            enabled: CaptureService.isLoaded
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on opacity {
                            enabled: CaptureService.isLoaded
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on width {
                            enabled: CastState.isTransitioningToCast
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.InOutCubic
                            }
                        }
                        Behavior on height {
                            enabled: CastState.isTransitioningToCast
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.InOutCubic
                            }
                        }
                        Behavior on x {
                            enabled: CastState.isTransitioningToCast
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.InOutCubic
                            }
                        }
                        Behavior on radius {
                            enabled: CastState.isTransitioningToCast
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.InOutCubic
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                        }

                        RowLayout {
                            id: mainRow
                            anchors.centerIn: parent
                            spacing: 8

                            IconButton {
                                iconName: "camera"
                                isActive: CaptureState.isShot
                                activeAccent: Config.ssAccent
                                onClicked: CaptureState.isShot = true
                            }
                            IconButton {
                                iconName: "video"
                                isActive: !CaptureState.isShot
                                activeAccent: Config.recAccent
                                onClicked: CaptureState.isShot = false
                            }

                            VDivider {}

                            Rectangle {
                                id: regionBtn
                                implicitHeight: 36
                                Layout.preferredWidth: (CaptureState.captureArea === "region" && SelectionState.rectWidth > SelectionState.minimumSize) ? regionBtnRow.implicitWidth + 16 : 36
                                radius: 18
                                color: CaptureState.captureArea === "region" ? Qt.rgba(CaptureState.accentColor.r, CaptureState.accentColor.g, CaptureState.accentColor.b, 0.15) : "transparent"
                                border.width: CaptureState.captureArea === "region" ? 1 : 0
                                border.color: CaptureState.accentColor

                                Behavior on Layout.preferredWidth {
                                    enabled: CaptureService.isLoaded
                                    NumberAnimation {
                                        duration: 350
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                RowLayout {
                                    id: regionBtnRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Icon {
                                        name: "crop"
                                        size: 20
                                        color: CaptureState.captureArea === "region" ? CaptureState.accentColor : Config.textMuted
                                    }

                                    Text {
                                        visible: CaptureState.captureArea === "region" && SelectionState.rectWidth > SelectionState.minimumSize
                                        text: Math.round(SelectionState.rectWidth) + " × " + Math.round(SelectionState.rectHeight)
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: CaptureState.accentColor
                                        Layout.rightMargin: 2
                                    }

                                    Icon {
                                        visible: CaptureState.captureArea === "region" && SelectionState.rectWidth > SelectionState.minimumSize
                                        name: "restore"
                                        size: 12
                                        color: CaptureState.accentColor
                                        opacity: 0.7
                                        Layout.rightMargin: 2
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        CaptureState.captureArea = "region";
                                        if (SelectionState.rectWidth > SelectionState.minimumSize) {
                                            SelectionState.clear();
                                        }
                                    }
                                }
                            }

                            IconButton {
                                iconName: "app-window"
                                isActive: CaptureState.captureArea === "window"
                                isEnabled: CaptureState.isShot
                                activeAccent: CaptureState.accentColor
                                onClicked: CaptureState.captureArea = "window"
                            }
                            IconButton {
                                iconName: "device-desktop"
                                isActive: CaptureState.captureArea === "screen"
                                activeAccent: CaptureState.accentColor
                                onClicked: CaptureState.captureArea = "screen"
                            }

                            VDivider {}

                            IconButton {
                                iconName: CaptureState.isShot ? (CaptureState.pointer ? "pointer" : "pointer-off") : (CaptureState.mic ? "microphone" : "microphone-off")
                                isActive: CaptureState.isShot ? CaptureState.pointer : CaptureState.mic
                                activeAccent: CaptureState.accentColor
                                onClicked: CaptureState.isShot ? (CaptureState.pointer = !CaptureState.pointer) : (CaptureState.mic = !CaptureState.mic)
                            }
                            IconButton {
                                iconName: CaptureState.isShot ? (CaptureState.annotate ? "pencil" : "pencil-off") : (CaptureState.audio ? "volume" : "volume-3")
                                isActive: CaptureState.isShot ? CaptureState.annotate : CaptureState.audio
                                activeAccent: CaptureState.accentColor
                                onClicked: CaptureState.isShot ? (CaptureState.annotate = !CaptureState.annotate) : (CaptureState.audio = !CaptureState.audio)
                            }

                            VDivider {}

                            IconButton {
                                isPrimary: true
                                iconName: CaptureState.captureArea === "region" && SelectionState.rectWidth <= SelectionState.minimumSize ? "crop" : CaptureState.isShot ? "camera-up" : "player-record"
                                activeAccent: CaptureState.accentColor
                                onClicked: CaptureService.executeAction()
                            }
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: recordingIndicator
        screen: CaptureService.activeScreen

        anchors.bottom: true
        anchors.right: true
        visible: CastState.isCasting && !CastState.isTransitioningToCast
        color: "transparent"

        implicitWidth: 240
        implicitHeight: 120

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "msnap-rec"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Item {
            anchors.fill: parent
            anchors.bottomMargin: 40
            anchors.rightMargin: 12

            Rectangle {
                id: pill
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: pillHover.containsMouse ? 150 : 6
                height: 44
                radius: pillHover.containsMouse ? 22 : 3
                color: CaptureState.pillBackground
                border.width: 1
                border.color: Config.recAccent
                clip: true

                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on radius {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 150
                    spacing: 12
                    opacity: pillHover.containsMouse ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    Rectangle {
                        implicitWidth: 10
                        implicitHeight: 10
                        radius: 5
                        color: Config.recAccent
                        Layout.leftMargin: 16
                        SequentialAnimation on opacity {
                            running: pillHover.containsMouse && CastState.isCasting
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 0.3
                                duration: 800
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 1.0
                                duration: 800
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: CastState.formatTime(CastState.castSeconds)
                        color: Config.textColor
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: 16
                        color: Config.borderColor
                    }

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 16
                        color: "transparent"
                        Layout.rightMargin: 8
                        Icon {
                            anchors.centerIn: parent
                            name: "player-stop"
                            color: Config.recAccent
                            size: 16
                        }
                    }
                }

                MouseArea {
                    id: pillHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: CastState.stopCast()
                }
            }
        }
    }
}
