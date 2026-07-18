import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import qs

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
            searchBar.text = "";
            listView.currentIndex = 0;
            root.windows = [];
            root.generation++;
            windowProcess.command = ["mmsg", "get", "all-clients"];
            windowProcess.running = true;
            Qt.callLater(() => {
                searchBar.forceActiveFocus();
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

            SearchBar {
                id: searchBar
                keyForwardTarget: listView

                onInputChanged: text => {
                    root.filterText = text;
                    if (listView.currentIndex >= root.filteredWindows.length)
                        listView.currentIndex = Math.max(0, root.filteredWindows.length - 1);
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
                visible: filterText !== "" && root.windows.length > 0 && root.filteredWindows.length === 0
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
                visible: root.filteredWindows.length > 0
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

                delegate:                 ChooserDelegate {
                    rowHeight: ListView.view.rowHeight

                    onClicked: {
                        listView.currentIndex = index;
                        root.selectCurrent();
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
                    console.error("Chooser: failed to parse mmsg output:", e);
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
