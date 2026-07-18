import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import qs

Item {
    id: root

    property bool active: false
    property bool showMonitors: false
    property var windows: []
    property var monitors: []
    property int generation: 0
    property string filterText: ""
    property string selectedType: "window"

    readonly property var filteredList: {
        const items = [];

        for (let i = 0; i < root.monitors.length; i++) {
            const m = root.monitors[i];
            items.push({
                _type: "monitor",
                title: m.name || "Unknown",
                identifier: m.name || "",
                subtitle: m.width + " × " + m.height,
                _originalIndex: i
            });
        }

        for (let i = 0; i < root.windows.length; i++) {
            const w = root.windows[i];
            items.push({
                _type: "window",
                title: w.title || "Untitled",
                identifier: w.foreign_toplevel_id || "",
                subtitle: w.appid || "",
                appid: w.appid || "",
                tags: w.tags || [],
                monitor: w.monitor || "",
                foreign_toplevel_id: w.foreign_toplevel_id || "",
                _originalIndex: i
            });
        }

        if (!filterText)
            return items;

        const q = filterText.toLowerCase().trim();
        if (!q)
            return items;

        const terms = q.split(/\s+/).filter(t => t);
        const scored = [];

        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            const title = (item.title || "").toLowerCase();
            const subtitle = (item.subtitle || "").toLowerCase();

            if (!terms.every(t => title.includes(t) || subtitle.includes(t)))
                continue;

            let score = 0;
            if (title.startsWith(q))
                score = 3;
            else if (terms.every(t => title.includes(t)))
                score = 2;
            else
                score = 1;

            scored.push({ item, score, originalIndex: i });
        }

        scored.sort((a, b) => b.score - a.score || a.originalIndex - b.originalIndex);
        return scored.map(s => s.item);
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
            root.monitors = [];
            root.generation++;
            windowProcess.command = ["mmsg", "get", "all-clients"];
            windowProcess.running = true;
            if (root.showMonitors) {
                monitorProcess.command = ["mmsg", "get", "all-monitors"];
                monitorProcess.running = true;
            }
            Qt.callLater(() => {
                searchBar.forceActiveFocus();
            });
        } else {
            if (windowProcess.running)
                windowProcess.running = false;
            if (monitorProcess.running)
                monitorProcess.running = false;
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
                placeholderText: root.showMonitors ? "Search windows, monitors..." : "Search windows..."

                onInputChanged: text => {
                    root.filterText = text;
                    if (listView.currentIndex >= root.filteredList.length)
                        listView.currentIndex = Math.max(0, root.filteredList.length - 1);
                }
            }

            Text {
                visible: {
                    const loading = windowProcess.running || (root.showMonitors && monitorProcess.running);
                    return loading && root.filteredList.length === 0;
                }
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
                visible: {
                    const done = !windowProcess.running && (!root.showMonitors || !monitorProcess.running);
                    return done && root.filteredList.length === 0 && root.active;
                }
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                text: root.showMonitors ? "No windows or monitors found" : "No windows found"
                color: Config.textMuted
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: filterText !== "" && root.filteredList.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                text: "No matching items"
                color: Config.textMuted
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            ListView {
                id: listView
                visible: root.filteredList.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.filteredList
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

                delegate: ChooserDelegate {
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
                    if (currentIndex < root.filteredList.length - 1)
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
        const item = root.filteredList[listView.currentIndex];
        if (item) {
            root.selectedType = item._type;
            root.accepted(item.title, item.identifier, item.appid || "");
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

    Process {
        id: monitorProcess
        running: false

        property int lastGeneration: 0

        stdout: StdioCollector {
            onStreamFinished: {
                if (monitorProcess.lastGeneration !== root.generation)
                    return;
                try {
                    const data = JSON.parse(this.text);
                    root.monitors = data.monitors || [];
                    listView.currentIndex = 0;
                } catch (e) {
                    console.error("Chooser: failed to parse monitor output:", e);
                    root.monitors = [];
                }
            }
        }

        onRunningChanged: {
            if (running)
                lastGeneration = root.generation;
        }
    }
}
