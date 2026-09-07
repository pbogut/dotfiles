import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import "Quota.js" as Quota

PluginComponent {
    id: root

    property bool shuttingDown: false
    readonly property var emptyStatus: ({
        "count": 0,
        "dominant_status": "empty",
        "counts": ({
            "blocked": 0,
            "working": 0,
            "done": 0,
            "idle": 0,
            "unknown": 0
        }),
        "groups": []
    })
    readonly property string helperUrl: Qt.resolvedUrl("./herdr-agents.py").toString()
    readonly property string helperPath: decodeURIComponent(helperUrl.replace(/^file:\/\//, ""))
    property var quotaProviders: ({})
    property var quotaData: ({})
    property bool quotaRefreshing: false
    property string quotaError: ""
    property string quotaRefreshSource: "cache"
    readonly property string quotaCacheHome: Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"
    readonly property string quotaPath: quotaCacheHome + "/opencode/quota-export.json"
    readonly property string quotaCliPath: quotaCacheHome + "/opencode/packages/@slkiser/opencode-quota@latest/node_modules/@slkiser/opencode-quota/dist/bin/opencode-quota.js"

    function publishStatus(status) {
        if (pluginService && pluginId)
            pluginService.setGlobalVar(pluginId, "status", status);
    }

    function publishQuota(quota) {
        quota.refreshing = quotaRefreshing;
        quota.error = quotaError;
        quota.refreshSource = quotaRefreshSource;
        quotaData = quota;
        if (pluginService && pluginId)
            pluginService.setGlobalVar(pluginId, "quota", quota);
    }

    function parseQuota(text) {
        if (!text || !text.trim())
            return null;
        try {
            const doc = JSON.parse(text);
            const incoming = Quota.mergeProviders({}, doc?.providers);
            if (!Object.keys(incoming).length)
                return null;
            const merged = Quota.mergeProviders(quotaProviders, incoming);
            if (merged !== quotaProviders) {
                quotaProviders = merged;
                if (pluginService && pluginId)
                    pluginService.savePluginState(pluginId, "quotaProviders", merged);
                publishQuota(Quota.render(merged));
            }
            return incoming;
        } catch (error) {
            console.warn("Herdr Agents: invalid quota data:", error);
            return null;
        }
    }

    function finishQuotaRefresh(error) {
        quotaRefreshing = false;
        quotaError = error;
        publishQuota(Quota.render(quotaProviders));
    }

    function refreshQuota() {
        if (quotaRefreshing || shuttingDown)
            return false;
        quotaRefreshing = true;
        quotaError = "";
        publishQuota(Quota.render(quotaProviders));
        quotaPollTimer.restart();
        let commandFinished = false;
        Proc.runCommand(
            null,
            ["env", "--chdir", Quickshell.env("HOME"), "node", quotaCliPath, "show", "--json"],
            (stdout, exitCode) => {
                // Proc can report both the timeout and the subsequent process exit.
                if (commandFinished || !root || root.shuttingDown)
                    return;
                commandFinished = true;
                const incoming = exitCode === 0 ? root.parseQuota(stdout) : null;
                if (incoming && Object.keys(root.quotaProviders).every(id => incoming[id])) {
                    root.quotaRefreshSource = "cli";
                    root.finishQuotaRefresh("");
                    return;
                }
                root.quotaError = exitCode === 0 ? "CLI returned incomplete quota"
                    : exitCode === 124 ? "Quota command timed out" : "Quota command failed";
                root.quotaRefreshSource = incoming ? "cli+export" : "export";
                quotaFile.reload();
                // With preload disabled, a read starts only when text is requested.
                quotaFile.text();
            },
            0,
            30000
        );
        return true;
    }

    Component.onCompleted: {
        publishStatus(emptyStatus);
        // Neither source may replace a newer snapshot retained from a previous run.
        if (pluginService && pluginId)
            quotaProviders = Quota.mergeProviders({}, pluginService.loadPluginState(pluginId, "quotaProviders", {}));
        refreshQuota();
        helperProcess.running = true;
    }
    Component.onDestruction: shuttingDown = true

    FileView {
        id: quotaFile

        path: root.quotaPath
        preload: false
        printErrors: false
        onLoaded: {
            const incoming = root.parseQuota(quotaFile.text());
            root.finishQuotaRefresh(incoming ? "" : root.quotaError + "; export has no usable quota");
        }
        onLoadFailed: root.finishQuotaRefresh(root.quotaError + "; export unavailable")
    }

    Timer {
        id: quotaPollTimer

        interval: 15 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refreshQuota()
    }

    IpcHandler {
        target: "herdr-agents"

        function refreshQuota(): string {
            return root.refreshQuota() ? "REFRESH_STARTED" : "REFRESH_IN_PROGRESS";
        }

        function quota(): string {
            return JSON.stringify(root.quotaData);
        }
    }

    Process {
        id: helperProcess

        command: [root.helperPath]
        onExited: (exitCode, exitStatus) => {
            root.publishStatus(root.emptyStatus);
            if (!root.shuttingDown)
                restartTimer.restart();
        }

        stdout: SplitParser {
            onRead: (line) => {
                try {
                    const status = JSON.parse(line);
                    if (typeof status.count === "number" && Array.isArray(status.groups)) {
                        root.publishStatus(status);
                    }
                } catch (error) {
                    console.warn("Herdr Agents: invalid helper output:", error);
                }
            }
        }

        stderr: SplitParser {
            onRead: (line) => {
                if (line.trim())
                    console.warn("Herdr Agents:", line);
            }
        }
    }

    Timer {
        id: restartTimer

        interval: 2000
        onTriggered: helperProcess.running = true
    }
}
