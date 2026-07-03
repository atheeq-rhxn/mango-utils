pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services

Item {
    id: root

    property bool active: false
    property var windows: []
    property int generation: 0

    signal accepted(string title, string identifier, string appId)
    signal cancelled

    visible: active

    onActiveChanged: {
        if (active) {
            listView.currentIndex = 0;
            root.windows = [];
            root.generation++;
            windowProcess.command = ["mmsg", "get", "all-clients"];
            windowProcess.running = true;
        } else {
            if (windowProcess.running)
                windowProcess.running = false;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Config.overlayColor
        opacity: Config.overlayAlpha

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancelled()
        }
    }

    Rectangle {
        id: popup
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.55, 460)
        height: Math.min(parent.height * 0.65, 480)
        radius: 12
        color: Config.surfaceColor
        border.color: Config.borderColor
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Text {
                visible: windowProcess.running && root.windows.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "Loading..."
                color: Config.textMuted
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: !windowProcess.running && root.windows.length === 0 && root.active
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "No windows found"
                color: Config.textMuted
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            ListView {
                id: listView
                visible: root.windows.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                focus: root.active
                model: root.windows
                currentIndex: 0
                highlightMoveDuration: 100
                interactive: true
                boundsBehavior: Flickable.StopAtBounds

                readonly property real rowHeight: 52

                highlight: Item {
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        color: Qt.rgba(Config.ssAccent.r, Config.ssAccent.g, Config.ssAccent.b, 0.12)
                        radius: 8
                    }
                }

                delegate: Item {
                    width: ListView.view.width
                    height: ListView.view.rowHeight
                    required property var modelData
                    required property int index

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

                                readonly property string resolvedIcon: Quickshell.iconPath(modelData.appid, true)

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
                                    visible: parent.resolvedIcon === ""
                                    anchors.centerIn: parent
                                    name: "app-window"
                                    size: 18
                                    color: Config.textMuted
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title || "Untitled"
                                    color: Config.textColor
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.appid || ""
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
                            onClicked: {
                                listView.currentIndex = index;
                                root.selectCurrent();
                            }
                        }
                    }
                }

                Keys.onUpPressed: event => {
                    if (currentIndex > 0)
                        currentIndex--;
                    event.accepted = true;
                }
                Keys.onDownPressed: event => {
                    if (currentIndex < root.windows.length - 1)
                        currentIndex++;
                    event.accepted = true;
                }
                Keys.onReturnPressed: root.selectCurrent()
                Keys.onEnterPressed: root.selectCurrent()
                Keys.onEscapePressed: root.cancelled()
            }
        }
    }

    function selectCurrent() {
        const w = root.windows[listView.currentIndex];
        if (w) {
            root.accepted(w.title || "Untitled", w.foreign_toplevel_id, w.appid || "");
        }
    }

    Process {
        id: windowProcess
        running: false

        property int lastGeneration: 0

        stdout: StdioCollector {
            onStreamFinished: {
                if (windowProcess.lastGeneration !== root.generation)
                    return;
                try {
                    const data = JSON.parse(this.text);
                    root.windows = data.clients || [];
                } catch (e) {
                    console.error("WindowPicker: failed to parse mmsg output:", e);
                    root.windows = [];
                }
            }
        }

        onRunningChanged: {
            if (running)
                lastGeneration = root.generation;
        }
    }
}
