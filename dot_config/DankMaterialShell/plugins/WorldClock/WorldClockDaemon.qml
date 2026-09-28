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
        Proc.runCommand(null, ["python3", helperPath], (stdout, exitCode) => {
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
        precision: SystemClock.Minutes
        onDateChanged: root.refresh()
    }

    Connections {
        target: SessionService
        function onSessionResumed() {
            root.refresh();
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
