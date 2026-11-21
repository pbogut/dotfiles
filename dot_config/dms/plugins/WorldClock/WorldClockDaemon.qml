import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services

PluginComponent {
    id: root

    property var snapshotData: ({})
    property bool refreshing: false
    property bool refreshPending: false
    readonly property string helperPath: decodeURIComponent(Qt.resolvedUrl("./world-clock.py").toString().replace(/^file:\/\//, ""))

    function publish() {
        if (pluginService && pluginId)
            pluginService.setGlobalVar(pluginId, "snapshot", snapshotData);
    }

    function refresh() {
        if (refreshing) {
            refreshPending = true;
            return;
        }
        refreshing = true;
        // A SystemClock tick can arrive early; convert its date, not Python's wall clock.
        const timestamp = String(minuteClock.date.getTime() / 1000);
        Proc.runCommand(null, ["python3", helperPath, "--timestamp", timestamp], (stdout, exitCode) => {
            let data;
            try {
                data = JSON.parse(stdout);
            } catch (_) {
                data = {error: "Unable to read world clock times."};
            }
            if (exitCode !== 0 && !data.error)
                data = {error: "World clock refresh failed."};
            root.snapshotData = data;
            root.refreshing = false;
            if (root.refreshPending) {
                root.refreshPending = false;
                root.refresh();
            }
        }, 0, 5000);
    }

    onSnapshotDataChanged: publish()
    onPluginServiceChanged: publish()
    onPluginIdChanged: publish()
    Component.onCompleted: refresh()

    SystemClock {
        id: minuteClock
        precision: SystemClock.Minutes
        onDateChanged: root.refresh()
    }

    Connections {
        target: SessionService
        function onSessionResumed() {
            // Re-read the clock before onDateChanged requests the new snapshot.
            minuteClock.enabled = false;
            minuteClock.enabled = true;
        }
    }

    IpcHandler {
        target: "world-clock"

        function refresh(): string {
            root.refresh();
            return "REFRESH_STARTED";
        }

        function status(): string {
            return JSON.stringify(root.snapshotData);
        }
    }
}
