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
    property string filterText: ""

    readonly property var filteredWindows: {
        if (!filterText) return root.windows;
        const q = filterText.toLowerCase().trim();
        if (!q) return root.windows;

        const terms = q.split(/\s+/).filter(t => t);
        const scored = [];

        for (let i = 0; i < root.windows.length; i++) {
            const w = root.windows[i];
            const title = (w.title || "").toLowerCase();
            const appid = (w.appid || "").toLowerCase();

            if (!terms.every(t => title.includes(t) || appid.includes(t)))
                continue;

            let score = 0;
            if (title.startsWith(q))
                score = 3;
            else if (terms.every(t => title.includes(t)))
                score = 2;
            else
                score = 1;

            scored.push({ window: w, score, originalIndex: i });
        }

        scored.sort((a, b) => b.score - a.score || a.originalIndex - b.originalIndex);
        return scored.map(s => s.window);
    }

    signal accepted(string title, string identifier, string appId)
    signal cancelled

    visible: active

    onActiveChanged: {
        if (active) {
            filterText = "";
            searchInput.text = "";
            listView.currentIndex = 0;
            root.windows = [];
            root.generation++;
            windowProcess.command = ["mmsg", "get", "all-clients"];
            windowProcess.running = true;
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
            });
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

            Rectangle {
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
                        text: "Search windows..."
                        color: Config.textMuted
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        visible: !parent.text
                    }

                    Keys.forwardTo: [listView]

                    onTextChanged: {
                        root.filterText = text;
                        if (listView.currentIndex >= filteredWindows.length)
                            listView.currentIndex = Math.max(0, filteredWindows.length - 1);
                    }
                }
            }

            Text {
                visible: windowProcess.running && root.windows.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
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
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                text: "No windows found"
                color: Config.textMuted
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: filterText !== "" && root.windows.length > 0 && filteredWindows.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                text: "No matching windows"
                color: Config.textMuted
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            ListView {
                id: listView
                visible: filteredWindows.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.filteredWindows
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
                                        visible: _winTags.length > 0
                                        implicitWidth: tagBadge.implicitWidth + 8
                                        height: 18
                                        radius: 4
                                        color: Qt.rgba(1, 1, 1, 0.04)

                                        Text {
                                            id: tagBadge
                                            anchors.centerIn: parent
                                            text: _winTags.join(", ")
                                            color: Config.textMuted
                                            font.pixelSize: 10
                                        }
                                    }

                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        visible: modelData.monitor && modelData.monitor !== ""
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
                    if (currentIndex < root.filteredWindows.length - 1)
                        currentIndex++;
                    event.accepted = true;
                }
                Keys.onReturnPressed: event => {
                    root.selectCurrent();
                    event.accepted = true;
                }
                Keys.onEnterPressed: event => {
                    root.selectCurrent();
                    event.accepted = true;
                }
                Keys.onEscapePressed: event => {
                    root.cancelled();
                    event.accepted = true;
                }
            }
        }
    }

    function selectCurrent() {
        const w = root.filteredWindows[listView.currentIndex];
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
                    const clients = data.clients || [];
                    for (let i = 0; i < clients.length; i++) {
                        if (clients[i].is_focused) {
                            const focused = clients.splice(i, 1)[0];
                            clients.unshift(focused);
                            break;
                        }
                    }
                    root.windows = clients;
                    listView.currentIndex = 0;
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
