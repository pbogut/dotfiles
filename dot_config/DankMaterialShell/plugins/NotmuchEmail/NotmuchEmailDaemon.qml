import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool refreshing: false
    property bool refreshPending: false
    property bool syncPending: false
    property var snapshotData: emptySnapshot
    readonly property var emptySnapshot: ({
        "unread": 0,
        "inbox": 0,
        "messages": [],
        "updatedAt": 0,
        "error": "",
        "refreshing": false
    })
    readonly property string helperUrl: Qt.resolvedUrl("./notmuch-email.py").toString()
    readonly property string helperPath: decodeURIComponent(helperUrl.replace(/^file:\/\//, ""))

    function publish(snapshot) {
        snapshotData = snapshot;
        if (pluginService && pluginId)
            pluginService.setGlobalVar(pluginId, "snapshot", snapshot);
    }

    function publishFailure(message) {
        publish({
            "unread": Number(snapshotData.unread || 0),
            "inbox": Number(snapshotData.inbox || 0),
            "messages": snapshotData.messages || [],
            "updatedAt": Number(snapshotData.updatedAt || 0),
            "error": String(message || "Unable to refresh the inbox"),
            "refreshing": false
        });
    }

    function beginRefresh() {
        refreshing = true;
        publish({
            "unread": Number(snapshotData.unread || 0),
            "inbox": Number(snapshotData.inbox || 0),
            "messages": snapshotData.messages || [],
            "updatedAt": Number(snapshotData.updatedAt || 0),
            "error": "",
            "refreshing": true
        });
    }

    function finishRefresh() {
        refreshing = false;
        if (syncPending) {
            syncPending = false;
            refreshPending = false;
            Qt.callLater(() => root.syncInbox());
            return;
        }
        if (refreshPending) {
            refreshPending = false;
            Qt.callLater(() => root.refresh());
        }
    }

    function runSnapshot() {
        Proc.runCommand(
            "notmuchEmail.snapshot",
            [helperPath, "snapshot"],
            (stdout, exitCode) => {
                let snapshot = null;
                const output = stdout.trim();
                if (output) {
                    try {
                        snapshot = JSON.parse(output);
                    } catch (error) {
                        snapshot = null;
                    }
                }

                if (exitCode !== 0) {
                    root.publishFailure(snapshot?.error || "Notmuch refresh failed");
                    root.finishRefresh();
                    return;
                }
                if (!snapshot) {
                    root.publishFailure("Notmuch returned invalid data");
                    root.finishRefresh();
                    return;
                }
                if (typeof snapshot.unread !== "number"
                        || typeof snapshot.inbox !== "number"
                        || !Array.isArray(snapshot.messages)) {
                    root.publishFailure("Notmuch returned invalid data");
                    root.finishRefresh();
                    return;
                }

                root.publish({
                    "unread": Math.max(0, Math.trunc(snapshot.unread)),
                    "inbox": Math.max(0, Math.trunc(snapshot.inbox)),
                    "messages": snapshot.messages,
                    "updatedAt": Number(snapshot.updatedAt || 0),
                    "error": String(snapshot.error || ""),
                    "refreshing": false
                });
                root.finishRefresh();
            },
            0,
            30000
        );
    }

    function refresh() {
        if (refreshing) {
            refreshPending = true;
            return false;
        }

        beginRefresh();
        runSnapshot();
        return true;
    }

    function syncInbox() {
        if (refreshing) {
            syncPending = true;
            return false;
        }

        beginRefresh();
        Proc.runCommand(
            "notmuchEmail.sync",
            ["network-sync", "inbox"],
            (_stdout, exitCode) => {
                if (exitCode !== 0) {
                    root.publishFailure(exitCode === 124
                        ? "Inbox sync timed out"
                        : "Inbox sync failed");
                    root.finishRefresh();
                    return;
                }

                refreshPending = false;
                root.runSnapshot();
            },
            0,
            300000
        );
        return true;
    }

    Component.onCompleted: {
        publish(emptySnapshot);
        refresh();
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "notmuch-email"

        function refresh(): string {
            return root.refresh() ? "REFRESH_STARTED" : "REFRESH_QUEUED";
        }

        function sync(): string {
            return root.syncInbox() ? "SYNC_STARTED" : "SYNC_QUEUED";
        }

        function status(): string {
            if (root.snapshotData.error)
                return "error\t" + root.snapshotData.error;
            return root.snapshotData.unread + "/" + root.snapshotData.inbox
                    + "\t" + root.snapshotData.messages.length + " shown";
        }
    }
}
