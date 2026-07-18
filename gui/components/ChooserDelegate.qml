pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import Quickshell
import qs

Item {
    id: root

    required property var modelData
    required property int index
    property real rowHeight: 52

    signal clicked

    width: ListView.view.width
    height: root.rowHeight

    readonly property bool _isMonitor: modelData._type === "monitor"
    readonly property var _winTags: modelData.tags || []

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 8
        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 6
                color: Qt.rgba(Config.ssAccent.r, Config.ssAccent.g, Config.ssAccent.b, 0.08)

                readonly property string resolvedIcon: root._isMonitor ? "" : Quickshell.iconPath(modelData.appid, true)

                Image {
                    visible: parent.resolvedIcon !== ""
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: parent.resolvedIcon
                    sourceSize: Qt.size(18, 18)
                    smooth: true
                }

                Icon {
                    anchors.centerIn: parent
                    name: root._isMonitor ? "device-desktop" : "app-window"
                    size: 18
                    color: Config.textMuted
                    visible: parent.resolvedIcon === ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: modelData.title || "Untitled"
                        color: Config.textColor
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        visible: !root._isMonitor && root._winTags.length > 0
                        implicitWidth: tagBadge.implicitWidth + 8
                        height: 18
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.04)

                        Text {
                            id: tagBadge
                            anchors.centerIn: parent
                            text: root._winTags.join(", ")
                            color: Config.textMuted
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        visible: root._isMonitor
                        implicitWidth: typeBadge.implicitWidth + 8
                        height: 18
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.04)

                        Text {
                            id: typeBadge
                            anchors.centerIn: parent
                            text: "Monitor"
                            color: Config.textMuted
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        visible: !root._isMonitor && modelData.monitor && modelData.monitor !== ""
                        implicitWidth: monBadge.implicitWidth + 8
                        height: 18
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.04)

                        Text {
                            id: monBadge
                            anchors.centerIn: parent
                            text: modelData.monitor || ""
                            color: Config.textMuted
                            font.pixelSize: 10
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root._isMonitor ? (modelData.subtitle || "") : (modelData.appid || "")
                    color: Config.textMuted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
