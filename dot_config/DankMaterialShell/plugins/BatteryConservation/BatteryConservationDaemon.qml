import QtQuick
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services

PluginComponent {
    id: root

    readonly property string enabledOutput: "Battery conservation mode is currently enabled."
    readonly property string disabledOutput: "Battery conservation mode is currently disabled."

    property bool modeKnown: false
    property bool modeEnabled: false
    property bool refreshing: false
    property bool changing: false
    property bool targetEnabled: false
    property bool refreshPending: false
    property string errorText: ""
    property double updatedAt: 0

    readonly property bool busy: refreshing || changing

    function statusText() {
        if (changing)
            return targetEnabled ? "Enabling battery conservation mode..." : "Disabling battery conservation mode...";
        if (refreshing)
            return "Checking battery conservation mode...";
        if (errorText)
            return errorText;
        if (modeKnown)
            return modeEnabled ? enabledOutput : disabledOutput;
        return "Battery conservation mode status is unknown.";
    }

    function publishState() {
        if (!pluginService || !pluginId)
            return;

        pluginService.setGlobalVar(pluginId, "conservation", {
            "known": modeKnown,
            "enabled": modeEnabled,
            "busy": busy,
            "refreshing": refreshing,
            "changing": changing,
            "error": errorText,
            "text": statusText(),
            "updatedAt": updatedAt
        });
    }

    function parseStatus(stdout, exitCode) {
        if (exitCode !== 0)
            return "error";

        const output = String(stdout || "").trim();
        if (output === enabledOutput)
            return "enabled";
        if (output === disabledOutput)
            return "disabled";
        return "error";
    }

    function drainRefreshQueue() {
        if (!refreshPending || busy)
            return;
        refreshPending = false;
        Qt.callLater(() => root.refresh());
    }

    function runStatus(showError, onDone) {
        if (busy) {
            refreshPending = true;
            return false;
        }

        refreshing = true;
        errorText = "";
        publishState();

        Proc.runCommand(
            "batteryConservation.status",
            ["ideapad-cm", "status"],
            (stdout, exitCode) => {
                const result = root.parseStatus(stdout, exitCode);
                root.refreshing = false;

                if (result === "enabled" || result === "disabled") {
                    root.modeKnown = true;
                    root.modeEnabled = result === "enabled";
                    root.errorText = "";
                    root.updatedAt = Date.now();
                } else {
                    root.modeKnown = false;
                    root.errorText = exitCode === 0
                        ? "ideapad-cm returned an unknown status."
                        : "Could not read battery conservation mode.";
                    if (showError)
                        ToastService.showError("Battery conservation status failed", root.errorText);
                }

                root.publishState();
                if (onDone)
                    onDone(result !== "error");
                root.drainRefreshQueue();
            },
            0,
            10000
        );
        return true;
    }

    function refresh() {
        return runStatus(false, null);
    }

    function finishChangeFailure(exitCode) {
        changing = false;
        errorText = exitCode === 126
            ? "Authentication was cancelled."
            : "Could not change battery conservation mode.";
        publishState();

        if (exitCode !== 126)
            ToastService.showError("Battery conservation change failed", errorText);
        drainRefreshQueue();
    }

    function verifyChange(requestedState) {
        changing = false;
        runStatus(false, ok => {
            if (!ok) {
                root.errorText = "The conservation mode change could not be verified.";
                root.publishState();
                ToastService.showError("Battery conservation change failed", root.errorText);
                return;
            }

            if (root.modeEnabled !== requestedState) {
                root.errorText = "Battery conservation mode did not change.";
                root.publishState();
                ToastService.showError("Battery conservation change failed", root.errorText);
                return;
            }

            ToastService.showInfo(
                requestedState ? "Battery conservation enabled" : "Battery conservation disabled"
            );
        });
    }

    function setMode(enabled) {
        if (busy)
            return false;

        targetEnabled = enabled;
        changing = true;
        errorText = "";
        publishState();

        Proc.runCommand(
            "batteryConservation.change",
            ["pkexec", "ideapad-cm", enabled ? "enable" : "disable"],
            (_stdout, exitCode) => {
                if (exitCode !== 0) {
                    root.finishChangeFailure(exitCode);
                    return;
                }
                root.verifyChange(enabled);
            },
            0,
            120000
        );
        return true;
    }

    function toggleMode() {
        if (busy)
            return false;

        return runStatus(true, ok => {
            if (ok)
                root.setMode(!root.modeEnabled);
        });
    }

    Component.onCompleted: {
        publishState();
        refresh();
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "battery-conservation"

        function refresh(): string {
            return root.refresh() ? "REFRESH_STARTED" : "REFRESH_QUEUED";
        }

        function enable(): string {
            return root.setMode(true) ? "ENABLE_STARTED" : "BUSY";
        }

        function disable(): string {
            return root.setMode(false) ? "DISABLE_STARTED" : "BUSY";
        }

        function toggle(): string {
            return root.toggleMode() ? "TOGGLE_STARTED" : "BUSY";
        }

        function status(): string {
            if (root.errorText)
                return "error\t" + root.errorText;
            return root.statusText();
        }
    }
}
