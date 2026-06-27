import QtQuick
import qs

Rectangle {
    id: root

    property string iconName: ""
    property bool isActive: false
    property bool isEnabled: true
    property bool isPrimary: false
    required property color activeAccent

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
        name: root.iconName
        color: root.isPrimary ? Config.bgColor : (root.isActive ? root.activeAccent : Config.textMuted)
        size: root.isPrimary ? 22 : 20
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.isEnabled
        cursorShape: root.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
