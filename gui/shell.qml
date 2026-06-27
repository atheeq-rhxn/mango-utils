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

    property bool isLoaded: false
    property bool isShot: true
    property string captureMode: "region"
    property bool isCollapsed: false

    property bool optPointer: false
    property bool optAnnotate: false
    property bool optMic: false
    property bool optAudio: false

    property string freezeState: "idle"

    property bool windowsVisible: true

    readonly property color accent: isShot ? Config.ssAccent : Config.recAccent
    readonly property color pillBg: Qt.rgba(Config.surfaceColor.r, Config.surfaceColor.g, Config.surfaceColor.b, 0.88)

    onIsShotChanged: {
        if (!isShot) {
            if (captureMode === "window")
                captureMode = "region";
            selectionState.cancelInteraction();
            selectionState.clampToScreen(activeScreen);
        }
    }

    onCaptureModeChanged: {
        if (!isLoaded)
            return;
        if (captureMode !== "region") {
            isCollapsed = false;
            selectionState.clear();
        }
    }

    onWindowsVisibleChanged: {
        if (!windowsVisible)
            selectionState.cancelInteraction();
    }

    Component.onCompleted: {
        globalState.isLoaded = true;
        if (isShot)
            enterFreeze();
    }

    Process {
        id: wayfreezeProcess

        command: ["wayfreeze", "--enable-keyboard", "--hide-cursor", "--after-freeze-cmd", "echo frozen"]

        running: false

        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf("frozen") !== -1) {
                    freezeState = "frozen";
                    windowsVisible = true;
                }
            }
        }

        onExited: (code, status) => {
            if (freezeState !== "idle") {
                freezeState = "idle";
            }
        }
    }

    Process {
        id: shotProcess

        running: false

        onExited: (code, status) => {
            if (wayfreezeProcess.running)
                wayfreezeProcess.running = false;
            freezeState = "idle";
            windowsVisible = false;
            if (!castState.isCasting)
                Qt.quit();
        }
    }

    function enterFreeze() {
        if (freezeState !== "idle")
            return;
        if (!Config.freezeEnabled) {
            freezeState = "frozen";
            windowsVisible = true;
            return;
        }
        freezeState = "freezing";
        windowsVisible = false;
        wayfreezeProcess.running = true;
    }

    function exitFreeze() {
        if (wayfreezeProcess.running)
            wayfreezeProcess.running = false;
        freezeState = "idle";
    }

    function closeAll() {
        if (wayfreezeProcess.running)
            wayfreezeProcess.running = false;
        freezeState = "idle";
        windowsVisible = false;
        if (!castState.isCasting)
            Qt.quit();
    }

    function buildArgs(sub, forShot) {
        const a = [Config.msnapPath, sub];
        if (captureMode === "region" && selectionState.rectWidth > selectionState.minimumSize && selectionState.rectHeight > selectionState.minimumSize) {
            const rx = Math.round(selectionState.rectX);
            const ry = Math.round(selectionState.rectY);
            const rw = Math.round(selectionState.rectWidth);
            const rh = Math.round(selectionState.rectHeight);
            a.push("-g", `${rx},${ry} ${rw}x${rh}`);
        } else if (captureMode === "window") {
            a.push("-w");
        }

        if (forShot) {
            if (optPointer)
                a.push("-p");
            if (optAnnotate)
                a.push("-a");
        } else {
            if (optMic)
                a.push("-m");
            if (optAudio)
                a.push("-a");
        }
        return a;
    }

    function executeAction() {
        if (captureMode === "region" && (selectionState.rectWidth <= selectionState.minimumSize || selectionState.rectHeight <= selectionState.minimumSize))
            return;
        isShot ? doShot() : castState.doCast();
    }

    function doShot() {
        windowsVisible = false;
        shotProcess.command = buildArgs("shot", true);
        shotProcess.running = true;
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
                    const modes = globalState.isShot ? ["region", "window", "screen"] : ["region", "screen"];
                    const i = modes.indexOf(globalState.captureMode);
                    globalState.captureMode = modes[((i < 0 ? 0 : i) + dir + modes.length) % modes.length];
                }

                Keys.onTabPressed: globalState.isShot = !globalState.isShot
                Keys.onBacktabPressed: globalState.isShot = !globalState.isShot
                Keys.onReturnPressed: globalState.executeAction()
                Keys.onEnterPressed: globalState.executeAction()
                Keys.onSpacePressed: globalState.executeAction()
                Keys.onEscapePressed: {
                    if (globalState.captureMode === "region" && selectionState.rectWidth > selectionState.minimumSize) {
                        selectionState.clear();
                    } else {
                        globalState.closeAll();
                    }
                }

                readonly property var keyHandlers: ({
                        [Qt.Key_H]: () => cycleTarget(-1),
                        [Qt.Key_J]: () => {
                            globalState.isShot = !globalState.isShot;
                        },
                        [Qt.Key_K]: () => {
                            globalState.isShot = !globalState.isShot;
                        },
                        [Qt.Key_L]: () => cycleTarget(1),
                        [Qt.Key_Left]: () => cycleTarget(-1),
                        [Qt.Key_Right]: () => cycleTarget(1),
                        [Qt.Key_S]: () => {
                            globalState.isShot = true;
                        },
                        [Qt.Key_V]: () => {
                            globalState.isShot = false;
                        },
                        [Qt.Key_R]: () => {
                            globalState.captureMode = "region";
                        },
                        [Qt.Key_W]: () => {
                            if (globalState.isShot)
                                globalState.captureMode = "window";
                        },
                        [Qt.Key_F]: () => {
                            globalState.captureMode = "screen";
                        },
                        [Qt.Key_P]: () => {
                            if (globalState.isShot)
                                globalState.optPointer = !globalState.optPointer;
                        },
                        [Qt.Key_E]: () => {
                            if (globalState.isShot)
                                globalState.optAnnotate = !globalState.optAnnotate;
                        },
                        [Qt.Key_M]: () => {
                            if (!globalState.isShot)
                                globalState.optMic = !globalState.optMic;
                        },
                        [Qt.Key_A]: () => {
                            if (!globalState.isShot)
                                globalState.optAudio = !globalState.optAudio;
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
                    enabled: globalState.captureMode !== "region"
                    onClicked: globalState.closeAll()
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
                color: globalState.pillBg
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
                visible: !castState.showCastAlert && !castState.isTransitioningToCast && globalState.captureMode === "region"
                z: 11
                width: 48
                height: 24
                radius: 12
                color: globalState.pillBg
                border.color: Config.borderColor
                border.width: 1

                x: (parent.width - width) / 2
                y: selectionState.isEditing ? parent.height + 10 : (globalState.isCollapsed ? parent.height - 24 : parent.height - toolbar.idleH - 40 - height + 12)

                Behavior on y {
                    enabled: globalState.isLoaded
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: globalState.isCollapsed ? 0 : -2
                    name: globalState.isCollapsed ? "chevron-up" : "chevron-down"
                    size: 16
                    color: Config.textMuted
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: globalState.isCollapsed = !globalState.isCollapsed
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

                y: selectionState.isEditing ? parent.height + 10 : (globalState.isCollapsed && globalState.captureMode === "region" ? parent.height + 10 : parent.height - idleH - 40)

                color: globalState.pillBg
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
                        isActive: globalState.isShot
                        activeAccent: Config.ssAccent
                        onClicked: globalState.isShot = true
                    }
                    IconButton {
                        iconName: "video"
                        isActive: !globalState.isShot
                        activeAccent: Config.recAccent
                        onClicked: globalState.isShot = false
                    }

                    VDivider {}

                    Rectangle {
                        id: regionBtn
                        implicitHeight: 36
                        Layout.preferredWidth: (globalState.captureMode === "region" && selectionState.rectWidth > selectionState.minimumSize) ? regionBtnRow.implicitWidth + 16 : 36
                        radius: 18
                        color: globalState.captureMode === "region" ? Qt.rgba(globalState.accent.r, globalState.accent.g, globalState.accent.b, 0.15) : "transparent"
                        border.width: globalState.captureMode === "region" ? 1 : 0
                        border.color: globalState.accent

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
                                color: globalState.captureMode === "region" ? globalState.accent : Config.textMuted
                            }

                            Text {
                                visible: globalState.captureMode === "region" && selectionState.rectWidth > selectionState.minimumSize
                                text: Math.round(selectionState.rectWidth) + " × " + Math.round(selectionState.rectHeight)
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: globalState.accent
                                Layout.rightMargin: 2
                            }

                            Icon {
                                visible: globalState.captureMode === "region" && selectionState.rectWidth > selectionState.minimumSize
                                name: "restore"
                                size: 12
                                color: globalState.accent
                                opacity: 0.7
                                Layout.rightMargin: 2
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                globalState.captureMode = "region";
                                if (selectionState.rectWidth > selectionState.minimumSize) {
                                    selectionState.clear();
                                }
                            }
                        }
                    }

                    IconButton {
                        iconName: "app-window"
                        isActive: globalState.captureMode === "window"
                        isEnabled: globalState.isShot
                        onClicked: globalState.captureMode = "window"
                    }
                    IconButton {
                        iconName: "device-desktop"
                        isActive: globalState.captureMode === "screen"
                        onClicked: globalState.captureMode = "screen"
                    }

                    VDivider {}

                    IconButton {
                        iconName: globalState.isShot ? (globalState.optPointer ? "pointer" : "pointer-off") : (globalState.optMic ? "microphone" : "microphone-off")
                        isActive: globalState.isShot ? globalState.optPointer : globalState.optMic
                        onClicked: globalState.isShot ? (globalState.optPointer = !globalState.optPointer) : (globalState.optMic = !globalState.optMic)
                    }
                    IconButton {
                        iconName: globalState.isShot ? (globalState.optAnnotate ? "pencil" : "pencil-off") : (globalState.optAudio ? "volume" : "volume-3")
                        isActive: globalState.isShot ? globalState.optAnnotate : globalState.optAudio
                        onClicked: globalState.isShot ? (globalState.optAnnotate = !globalState.optAnnotate) : (globalState.optAudio = !globalState.optAudio)
                    }

                    VDivider {}

                    IconButton {
                        isPrimary: true
                        iconName: globalState.captureMode === "region" && selectionState.rectWidth <= selectionState.minimumSize ? "crop" : globalState.isShot ? "camera-up" : "player-record"
                        onClicked: globalState.executeAction()
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
        property color activeAccent: globalState.accent
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
                color: globalState.pillBg
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
