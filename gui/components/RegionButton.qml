import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Rectangle {
    id: root

    property int _contentWidth: regionRow.implicitWidth + 16

    implicitHeight: 36
    Layout.preferredWidth: (CaptureState.captureArea === "region" && SelectionState.rectWidth > SelectionState.minimumSize) ? _contentWidth : 36
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
        id: regionRow
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
            if (SelectionState.rectWidth > SelectionState.minimumSize)
                SelectionState.clear();
        }
    }
}
