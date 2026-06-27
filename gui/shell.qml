pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: globalState

    property var activeScreen: null

    SelectionState {
        id: selectionState
    }

    CastState {
        id: castState
    }

    FreezeState {
        id: freezeState
    }

    CaptureState {
        id: captureState
    }

    CaptureService {
        id: captureService
    }

    property bool isLoaded: false

    property bool windowsVisible: true

    onWindowsVisibleChanged: {
        if (!windowsVisible)
            selectionState.cancelInteraction();
    }

    Component.onCompleted: {
        globalState.isLoaded = true;
        if (captureState.isShot)
            freezeState.enter();
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
            visible: globalState.windowsVisible
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
                    const modes = captureState.isShot ? ["region", "window", "screen"] : ["region", "screen"];
                    const i = modes.indexOf(captureState.captureArea);
                    captureState.captureArea = modes[((i < 0 ? 0 : i) + dir + modes.length) % modes.length];
                }

                Keys.onTabPressed: captureState.isShot = !captureState.isShot
                Keys.onBacktabPressed: captureState.isShot = !captureState.isShot
                Keys.onReturnPressed: captureService.executeAction()
                Keys.onEnterPressed: captureService.executeAction()
                Keys.onSpacePressed: captureService.executeAction()
                Keys.onEscapePressed: {
                    if (captureState.captureArea === "region" && selectionState.rectWidth > selectionState.minimumSize) {
                        selectionState.clear();
                    } else {
                        captureService.closeAll();
                    }
                }

                readonly property var keyHandlers: ({
                        [Qt.Key_H]: () => cycleTarget(-1),
                        [Qt.Key_J]: () => {
                            captureState.isShot = !captureState.isShot;
                        },
                        [Qt.Key_K]: () => {
                            captureState.isShot = !captureState.isShot;
                        },
                        [Qt.Key_L]: () => cycleTarget(1),
                        [Qt.Key_Left]: () => cycleTarget(-1),
                        [Qt.Key_Right]: () => cycleTarget(1),
                        [Qt.Key_S]: () => {
                            captureState.isShot = true;
                        },
                        [Qt.Key_V]: () => {
                            captureState.isShot = false;
                        },
                        [Qt.Key_R]: () => {
                            captureState.captureArea = "region";
                        },
                        [Qt.Key_W]: () => {
                            if (captureState.isShot)
                                captureState.captureArea = "window";
                        },
                        [Qt.Key_F]: () => {
                            captureState.captureArea = "screen";
                        },
                        [Qt.Key_P]: () => {
                            if (captureState.isShot)
                                captureState.pointer = !captureState.pointer;
                        },
                        [Qt.Key_E]: () => {
                            if (captureState.isShot)
                                captureState.annotate = !captureState.annotate;
                        },
                        [Qt.Key_M]: () => {
                            if (!captureState.isShot)
                                captureState.mic = !captureState.mic;
                        },
                        [Qt.Key_A]: () => {
                            if (!captureState.isShot)
                                captureState.audio = !captureState.audio;
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
                    enabled: captureState.captureArea !== "region"
                    onClicked: captureService.closeAll()
                    z: 0
                }

                HoverHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onPointChanged: globalState.activeScreen = windowRoot.modelData
                }

                RegionSelector {
                    id: regionSelector
                    anchors.fill: parent
                    z: 1
                    scaleFactor: windowRoot.screen ? windowRoot.screen.devicePixelRatio : 1.0
                    screenOffsetX: windowRoot.screen.x
                    screenOffsetY: windowRoot.screen.y
                }
            }
        }
    }

    PanelWindow {
        id: uiOverlay
        screen: globalState.activeScreen

        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 160

        visible: globalState.windowsVisible
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "msnap-ui"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Item {
            anchors.fill: parent

            Rectangle {
                visible: castState.showCastAlert
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 40
                width: toastRow.implicitWidth + 24
                height: 44
                radius: 22
                color: captureState.pillBackground
                border.color: Config.recAccent
                border.width: 1
                opacity: castState.showCastAlert ? 1.0 : 0.0
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
                            running: castState.showCastAlert
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
                visible: !castState.showCastAlert && !castState.isTransitioningToCast && captureState.captureArea === "region"
                z: 11
                width: 48
                height: 24
                radius: 12
                color: captureState.pillBackground
                border.color: Config.borderColor
                border.width: 1

                x: (parent.width - width) / 2
                y: selectionState.isEditing ? parent.height + 10 : (captureState.toolbarCollapsed ? parent.height - 24 : parent.height - toolbar.idleH - 40 - height + 12)

                Behavior on y {
                    enabled: globalState.isLoaded
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: captureState.toolbarCollapsed ? 0 : -2
                    name: captureState.toolbarCollapsed ? "chevron-up" : "chevron-down"
                    size: 16
                    color: Config.textMuted
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: captureState.toolbarCollapsed = !captureState.toolbarCollapsed
                }
            }

            Rectangle {
                id: toolbar
                visible: !castState.showCastAlert
                clip: true
                z: 10

                readonly property real idleW: mainRow.implicitWidth + 32
                readonly property real idleH: 56

                x: castState.isTransitioningToCast ? parent.width - 6 - 12 : (parent.width - width) / 2
                width: castState.isTransitioningToCast ? 6 : idleW
                height: castState.isTransitioningToCast ? 44 : idleH
                radius: castState.isTransitioningToCast ? 3 : idleH / 2

                y: selectionState.isEditing ? parent.height + 10 : (captureState.toolbarCollapsed && captureState.captureArea === "region" ? parent.height + 10 : parent.height - idleH - 40)

                color: captureState.pillBackground
                border.color: castState.isTransitioningToCast ? Config.recAccent : Config.borderColor
                border.width: 1
                opacity: castState.isTransitioningToCast ? 0.0 : (selectionState.isEditing ? 0.0 : 1.0)

                Behavior on y {
                    enabled: globalState.isLoaded
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    enabled: globalState.isLoaded
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on width {
                    enabled: castState.isTransitioningToCast
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.InOutCubic
                    }
                }
                Behavior on height {
                    enabled: castState.isTransitioningToCast
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.InOutCubic
                    }
                }
                Behavior on x {
                    enabled: castState.isTransitioningToCast
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.InOutCubic
                    }
                }
                Behavior on radius {
                    enabled: castState.isTransitioningToCast
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
                        isActive: captureState.isShot
                        activeAccent: Config.ssAccent
                        onClicked: captureState.isShot = true
                    }
                    IconButton {
                        iconName: "video"
                        isActive: !captureState.isShot
                        activeAccent: Config.recAccent
                        onClicked: captureState.isShot = false
                    }

                    VDivider {}

                    Rectangle {
                        id: regionBtn
                        implicitHeight: 36
                        Layout.preferredWidth: (captureState.captureArea === "region" && selectionState.rectWidth > selectionState.minimumSize) ? regionBtnRow.implicitWidth + 16 : 36
                        radius: 18
                        color: captureState.captureArea === "region" ? Qt.rgba(captureState.accentColor.r, captureState.accentColor.g, captureState.accentColor.b, 0.15) : "transparent"
                        border.width: captureState.captureArea === "region" ? 1 : 0
                        border.color: captureState.accentColor

                        Behavior on Layout.preferredWidth {
                            enabled: globalState.isLoaded
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
                                color: captureState.captureArea === "region" ? captureState.accentColor : Config.textMuted
                            }

                            Text {
                                visible: captureState.captureArea === "region" && selectionState.rectWidth > selectionState.minimumSize
                                text: Math.round(selectionState.rectWidth) + " × " + Math.round(selectionState.rectHeight)
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: captureState.accentColor
                                Layout.rightMargin: 2
                            }

                            Icon {
                                visible: captureState.captureArea === "region" && selectionState.rectWidth > selectionState.minimumSize
                                name: "restore"
                                size: 12
                                color: captureState.accentColor
                                opacity: 0.7
                                Layout.rightMargin: 2
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                captureState.captureArea = "region";
                                if (selectionState.rectWidth > selectionState.minimumSize) {
                                    selectionState.clear();
                                }
                            }
                        }
                    }

                    IconButton {
                        iconName: "app-window"
                        isActive: captureState.captureArea === "window"
                        isEnabled: captureState.isShot
                        onClicked: captureState.captureArea = "window"
                    }
                    IconButton {
                        iconName: "device-desktop"
                        isActive: captureState.captureArea === "screen"
                        onClicked: captureState.captureArea = "screen"
                    }

                    VDivider {}

                    IconButton {
                        iconName: captureState.isShot ? (captureState.pointer ? "pointer" : "pointer-off") : (captureState.mic ? "microphone" : "microphone-off")
                        isActive: captureState.isShot ? captureState.pointer : captureState.mic
                        onClicked: captureState.isShot ? (captureState.pointer = !captureState.pointer) : (captureState.mic = !captureState.mic)
                    }
                    IconButton {
                        iconName: captureState.isShot ? (captureState.annotate ? "pencil" : "pencil-off") : (captureState.audio ? "volume" : "volume-3")
                        isActive: captureState.isShot ? captureState.annotate : captureState.audio
                        onClicked: captureState.isShot ? (captureState.annotate = !captureState.annotate) : (captureState.audio = !captureState.audio)
                    }

                    VDivider {}

                    IconButton {
                        isPrimary: true
                        iconName: captureState.captureArea === "region" && selectionState.rectWidth <= selectionState.minimumSize ? "crop" : captureState.isShot ? "camera-up" : "player-record"
                        onClicked: captureService.executeAction()
                    }
                }
            }
        }
    }

    component IconButton: Rectangle {
        property string iconName: ""
        property bool isActive: false
        property bool isEnabled: true
        property bool isPrimary: false
        property color activeAccent: captureState.accentColor
        signal clicked

        width: isPrimary ? 44 : 36
        height: isPrimary ? 44 : 36
        radius: height / 2
        opacity: isEnabled ? 1.0 : 0.3
        color: isPrimary ? activeAccent : (isActive ? Qt.rgba(activeAccent.r, activeAccent.g, activeAccent.b, 0.15) : "transparent")
        border.width: isActive && !isPrimary ? 1 : 0
        border.color: activeAccent

        Icon {
            anchors.centerIn: parent
            name: parent.iconName
            color: parent.isPrimary ? Config.bgColor : (parent.isActive ? parent.activeAccent : Config.textMuted)
            size: parent.isPrimary ? 22 : 20
        }

        MouseArea {
            anchors.fill: parent
            enabled: parent.isEnabled
            cursorShape: parent.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.clicked()
        }
    }

    component VDivider: Rectangle {
        width: 1
        height: 24
        color: Config.borderColor
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 2
        Layout.rightMargin: 2
    }

    PanelWindow {
        id: recordingIndicator
        screen: globalState.activeScreen

        anchors.bottom: true
        anchors.right: true
        visible: castState.isCasting && !castState.isTransitioningToCast
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
                color: captureState.pillBackground
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
                            running: pillHover.containsMouse && castState.isCasting
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
                        text: castState.formatTime(castState.castSeconds)
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
                    onClicked: castState.stopCast()
                }
            }
        }
    }
}
