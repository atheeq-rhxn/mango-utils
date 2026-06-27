pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Color scheme
    property color ssAccent: "#7aa2f7"
    property color recAccent: "#f7768e"
    property color bgColor: "#13141d"
    property color surfaceColor: "#1a1b26"
    property color textColor: "#c0caf5"
    property color textMuted: "#565f89"
    property color borderColor: "#2a2d3e"
    property color overlayColor: "#000000"
    property real overlayAlpha: 0.5
    property color handleColor: "#ffffff"
    property color dimLabelBg: "#000000"
    property real dimLabelAlpha: 0.75
    property color instructionColor: "#ffffff"
    property real instructionAlpha: 0.65

    readonly property bool freezeEnabled: Quickshell.env("MSNAP_NO_FREEZE") !== "1"

    // Paths
    readonly property string homePath: Quickshell.env("HOME")

    // The path to the msnap binary (injected at build time by the Makefile)
    // Fallback to "msnap" so it works via $PATH during local development testing
    readonly property string msnapPath: "@BIN_PATH@" === "@" + "BIN_PATH@" ? "msnap" : "@BIN_PATH@"

    readonly property string pidFilePath: "/tmp/msnap-cast.pid"

    // UI Constants
    readonly property int panelWidth: 276
    readonly property int panelBottomMargin: 68
    readonly property int buttonHeight: 64
    readonly property int toggleButtonSize: 36
    readonly property int defaultSpacing: 6
    readonly property int defaultBorderRadius: 8

    readonly property string configPath: Quickshell.env("MSNAP_GUI_CONFIG")

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        onLoaded: root.loadConfig(text())
        onFileChanged: reload()
    }

    function loadConfig(data: string) {
        if (!data)
            return;

        try {
            const lines = data.split('\n');
            const updates = {};

            for (const line of lines) {
                const trimmed = line.trim();
                if (!trimmed || trimmed.startsWith('#'))
                    continue;

                const eqIndex = trimmed.indexOf('=');
                if (eqIndex === -1)
                    continue;

                const key = trimmed.substring(0, eqIndex).trim();
                const value = trimmed.substring(eqIndex + 1).trim();

                // Convert snake_case to camelCase
                const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());

                if (camelKey in root && camelKey !== "freezeEnabled") {
                    if (value === "true")
                        updates[camelKey] = true;
                    else if (value === "false")
                        updates[camelKey] = false;
                    else
                        updates[camelKey] = value;
                }
            }

            // Batch update to minimize binding notifications
            for (const [key, value] of Object.entries(updates)) {
                root[key] = value;
            }
        } catch (error) {
            console.error("Config parsing error:", error);
            console.error("Falling back to default configuration");
        }
    }
}
