import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string name: ""
    property color color: "white"
    property int size: 24

    implicitWidth: size
    implicitHeight: size

    Image {
        id: iconImage
        anchors.centerIn: parent
        width: root.size
        height: root.size
        source: "../icons/" + root.name + ".svg"
        sourceSize: Qt.size(root.size, root.size)
        smooth: true
        visible: false
    }

    MultiEffect {
        anchors.fill: iconImage
        source: iconImage
        colorization: 1.0
        brightness: 1.0
        colorizationColor: root.color
    }
}
