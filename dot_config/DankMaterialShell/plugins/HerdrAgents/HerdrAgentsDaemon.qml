import QtQuick
import Quickshell
import Quickshell.Io
import qs.Modules.Plugins

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
    readonly property var emptyQuota: ({
        "updatedAt": 0,
        "cacheAgeSeconds": 0,
        "rows": []
    })
    readonly property string quotaPath: {
        const cacheHome = Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache";
        return cacheHome + "/opencode/quota-export.json";
    }

    function publishStatus(status) {
        if (pluginService && pluginId)
            pluginService.setGlobalVar(pluginId, "status", status);
    }

    function publishQuota(quota) {
        if (pluginService && pluginId)
            pluginService.setGlobalVar(pluginId, "quota", quota);
    }

    function parseQuota(text) {
        if (!text || !text.trim()) {
            publishQuota(emptyQuota);
            return;
        }
        try {
            const doc = JSON.parse(text);
            const providers = doc.providers || {};
            const rows = [];
            for (const providerId in providers) {
                const provider = providers[providerId];
                if (!provider || (provider.status !== "ok" && provider.status !== "partial"))
                    continue;
                const entries = provider.entries || [];
                for (let i = 0; i < entries.length; i++) {
                    const entry = entries[i];
                    if (!entry || entry.renderType !== "percent")
                        continue;
                    const remaining = Number(entry.percentRemaining);
                    if (!isFinite(remaining))
                        continue;
                    rows.push({
                        "providerId": providerId,
                        "label": String(entry.name || providerId),
                        "window": String(entry.window || ""),
                        "percentRemaining": Math.max(0, Math.min(100, remaining)),
                        "resetAt": Number(entry.resetAt || 0)
                    });
                }
            }
            const windowOrder = {
                "5h": 0,
                "Weekly": 1,
                "Monthly": 2
            };
            rows.sort(function(a, b) {
                if (a.providerId < b.providerId)
                    return -1;
                if (a.providerId > b.providerId)
                    return 1;
                const aRank = windowOrder[a.window] ?? 99;
                const bRank = windowOrder[b.window] ?? 99;
                if (aRank !== bRank)
                    return aRank - bRank;
                if (a.label < b.label)
                    return -1;
                if (a.label > b.label)
                    return 1;
                return 0;
            });
            publishQuota({
                "updatedAt": Number(doc.exportedAt || 0),
                "cacheAgeSeconds": Number(doc.cacheAgeSeconds || 0),
                "rows": rows
            });
        } catch (error) {
            console.warn("Herdr Agents: invalid quota export:", error);
            publishQuota(emptyQuota);
        }
    }

    Component.onCompleted: {
        publishStatus(emptyStatus);
        publishQuota(emptyQuota);
        helperProcess.running = true;
    }
    Component.onDestruction: shuttingDown = true

    FileView {
        id: quotaFile

        path: root.quotaPath
        watchChanges: true
        onLoaded: root.parseQuota(quotaFile.text())
        onFileChanged: quotaFile.reload()
        onLoadFailed: function (error) {
            root.publishQuota(root.emptyQuota);
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
