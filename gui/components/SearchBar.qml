import QtQuick
import QtQuick.Layouts

import qs

Rectangle {
    id: root

    property alias text: searchInput.text
    property string placeholderText: "Search windows..."
    property Item keyForwardTarget: null

    signal inputChanged(string text)

    function forceActiveFocus() {
        searchInput.forceActiveFocus();
    }

    Layout.fillWidth: true
    Layout.topMargin: 12
    Layout.leftMargin: 12
    Layout.rightMargin: 12
    height: 36
    radius: 8
    color: searchInput.activeFocus
        ? Qt.rgba(Config.ssAccent.r, Config.ssAccent.g, Config.ssAccent.b, 0.08)
        : Qt.rgba(1, 1, 1, 0.05)
    border.color: searchInput.activeFocus ? Config.ssAccent : Config.borderColor
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Icon {
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        name: "search"
        size: 16
        color: searchInput.activeFocus ? Config.ssAccent : Config.textMuted
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Icon {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        name: "x"
        size: 16
        color: Config.textMuted
        visible: searchInput.text.length > 0

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                searchInput.text = "";
                searchInput.forceActiveFocus();
            }
        }
    }

    TextInput {
        id: searchInput
        anchors.fill: parent
        anchors.leftMargin: 34
        anchors.rightMargin: 34
        verticalAlignment: Text.AlignVCenter
        color: Config.textColor
        font.pixelSize: 13
        selectionColor: Config.ssAccent
        clip: true

        Text {
            anchors.fill: parent
            text: root.placeholderText
            color: Config.textMuted
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            visible: !parent.text
        }

        Keys.forwardTo: root.keyForwardTarget ? [root.keyForwardTarget] : []

        onTextChanged: root.inputChanged(text)
    }
}
