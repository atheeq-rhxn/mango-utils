import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Rectangle {
    id: root

    property int _contentWidth: windowRow.implicitWidth + 16

    implicitHeight: 36
    Layout.preferredWidth: (CaptureState.captureArea === "window" && CaptureState.hasChosenWindow) ? _contentWidth : 36
    radius: 18
    color: CaptureState.captureArea === "window" ? Qt.rgba(CaptureState.accentColor.r, CaptureState.accentColor.g, CaptureState.accentColor.b, 0.15) : "transparent"
    border.width: CaptureState.captureArea === "window" ? 1 : 0
    border.color: CaptureState.accentColor
    enabled: CaptureState.isShot
    opacity: enabled ? 1.0 : 0.3

    Behavior on Layout.preferredWidth {
        enabled: CaptureService.isLoaded
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }

    readonly property string windowIcon: {
        if (CaptureState.hasChosenWindow && CaptureState.chosenWindowAppId) {
            const path = Quickshell.iconPath(CaptureState.chosenWindowAppId, true);
            if (path !== "")
                return path;
        }
        return "";
    }

    RowLayout {
        id: windowRow
        anchors.centerIn: parent
        spacing: 5

        Image {
            visible: root.windowIcon !== ""
            width: 20
            height: 20
            source: root.windowIcon
            sourceSize: Qt.size(20, 20)
            smooth: true
        }

        Icon {
            visible: root.windowIcon === ""
            name: "app-window"
            size: 20
            color: CaptureState.captureArea === "window" ? CaptureState.accentColor : Config.textMuted
        }

        Text {
            visible: CaptureState.captureArea === "window" && CaptureState.hasChosenWindow
            text: CaptureState.chosenWindowTitle.length > 24 ? CaptureState.chosenWindowTitle.substring(0, 24) + "…" : CaptureState.chosenWindowTitle
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: CaptureState.accentColor
            Layout.rightMargin: 2
        }

        Icon {
            visible: CaptureState.captureArea === "window" && CaptureState.hasChosenWindow
            name: "restore"
            size: 12
            color: CaptureState.accentColor
            opacity: 0.7
            Layout.rightMargin: 2
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (CaptureState.captureArea === "window")
                CaptureState.resetWindowChoice();
            else
                CaptureState.captureArea = "window";
        }
    }
}
