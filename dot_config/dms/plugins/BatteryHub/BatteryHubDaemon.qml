import QtQuick
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services

PluginComponent {
    id: root

    readonly property string enabledOutput: "Battery conservation mode is currently enabled."
    readonly property string disabledOutput: "Battery conservation mode is currently disabled."
    readonly property string asusHelperUrl: Qt.resolvedUrl("./asus-rog-mouse-battery.py").toString()
    readonly property string asusHelperPath: decodeURIComponent(asusHelperUrl.replace(/^file:\/\//, ""))
    readonly property string zmkHelperUrl: Qt.resolvedUrl("./zmk-battery.py").toString()
    readonly property string zmkHelperPath: decodeURIComponent(zmkHelperUrl.replace(/^file:\/\//, ""))
    property var zmkState: ({"available": false, "devices": [], "barDevices": [], "error": ""})
    property var zmkPaths: []
    property bool zmkDiscovering: false
    property bool zmkRestartPending: false
    property bool shuttingDown: false
    property double zmkUpdatedAt: 0

    property bool availabilityKnown: false
    property bool commandAvailable: false
    property bool checkingAvailability: false
    property bool modeKnown: false
    property bool modeEnabled: false
    property bool refreshing: false
    property bool changing: false
    property bool targetEnabled: false
    property bool refreshPending: false
    property string errorText: ""
    property double updatedAt: 0
    property bool razerRefreshing: false
    property bool razerRefreshPending: false
    property var razerDevices: []
    readonly property bool razerDeviceAvailable: razerDevices.length > 0
    property string razerErrorText: ""
    property double razerUpdatedAt: 0
    property bool asusAvailabilityKnown: false
    property bool asusDeviceAvailable: false
    property bool asusRefreshing: false
    property bool asusDiscovering: false
    property bool asusDiscoveryPending: false
    property bool asusRefreshPending: false
    property string asusDevicePath: ""
    property var asusDevices: []
    property string asusErrorText: ""
    property double asusUpdatedAt: 0

    readonly property bool busy: checkingAvailability || refreshing || changing

    function statusText() {
        if (changing)
            return targetEnabled ? "Enabling battery conservation mode..." : "Disabling battery conservation mode...";
        if (checkingAvailability)
            return "Checking battery conservation mode availability...";
        if (availabilityKnown && !commandAvailable)
            return "Battery conservation mode is unavailable.";
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
            "available": availabilityKnown && commandAvailable,
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

    function peripheralErrorText() {
        const errors = [];
        if (razerErrorText)
            errors.push(razerErrorText);
        if (asusErrorText)
            errors.push(asusErrorText);
        if (zmkState.error)
            errors.push(zmkState.error);
        return errors.join(" ");
    }

    function publishPeripheralState() {
        if (!pluginService || !pluginId)
            return;

        pluginService.setGlobalVar(pluginId, "peripheralBatteries", {
            "available": razerDeviceAvailable
                || (asusAvailabilityKnown && asusDeviceAvailable) || zmkState.available,
            "devices": razerDevices.concat(asusDevices, zmkState.devices),
            "barDevices": razerDevices.concat(asusDevices, zmkState.barDevices),
            "refreshing": razerRefreshing || asusRefreshing || zmkDiscovering,
            "error": peripheralErrorText(),
            "updatedAt": Math.max(razerUpdatedAt, asusUpdatedAt, zmkUpdatedAt)
        });
    }

    function clearZmk(error) {
        zmkState = {"available": false, "devices": [], "barDevices": [], "error": error};
        publishPeripheralState();
    }

    function startZmkReader() {
        zmkRestartPending = false;
        if (shuttingDown || zmkPaths.length === 0)
            return;
        zmkReader.command = [zmkHelperPath, "watch"].concat(zmkPaths);
        zmkReader.running = true;
    }

    function discoverZmk() {
        if (zmkDiscovering || zmkRestartPending || shuttingDown)
            return false;
        zmkDiscovering = true;
        publishPeripheralState();
        Proc.runCommand("batteryHub.discoverZmk", [zmkHelperPath, "discover"], (stdout, exitCode) => {
            if (root.shuttingDown)
                return;
            root.zmkDiscovering = false;
            let paths = null;
            try {
                paths = JSON.parse(stdout);
            } catch (error) {}
            if (exitCode !== 0 || !Array.isArray(paths) || !paths.every(path => typeof path === "string")) {
                root.zmkState = Object.assign({}, root.zmkState, {"error": "Could not discover ZMK dongles."});
                root.publishPeripheralState();
                return;
            }
            root.zmkPaths = paths;
            const devices = root.zmkState.devices.filter(device => paths.includes(device.group));
            root.zmkState = {
                "available": devices.length > 0,
                "devices": devices,
                "barDevices": root.zmkState.barDevices.filter(device => paths.includes(device.group)),
                "error": ""
            };
            root.publishPeripheralState();
            if (zmkReader.running) {
                root.zmkRestartPending = true;
                zmkReader.running = false;
            } else {
                root.startZmkReader();
            }
        }, 0, 10000);
        return true;
    }

    function acceptZmkState(state) {
        // A reopened port initially emits a waiting row. Keep its previous
        // snapshot until it reports slots, but never retain disconnected ports.
        const waitingGroups = state.devices.filter(device => device.status === "Waiting for battery data")
            .map(device => device.group);
        const previous = zmkState;
        let devices = [];
        for (const device of state.devices) {
            const retained = waitingGroups.includes(device.group)
                ? previous.devices.filter(old => old.group === device.group) : [];
            devices = devices.concat(retained.length > 0 ? retained : [device]);
        }
        state.devices = devices;
        state.barDevices = state.barDevices.concat(
            previous.barDevices.filter(device => waitingGroups.includes(device.group))
        );
        zmkState = state;
        zmkUpdatedAt = Date.now();
        publishPeripheralState();
    }

    function finishRazerRefresh() {
        razerRefreshing = false;
        publishPeripheralState();
        if (!razerRefreshPending)
            return;
        razerRefreshPending = false;
        Qt.callLater(() => root.refreshRazer());
    }

    function refreshRazer() {
        if (razerRefreshing) {
            razerRefreshPending = true;
            return false;
        }

        razerRefreshing = true;
        razerErrorText = "";
        publishPeripheralState();

        Proc.runCommand(
            "batteryHub.razerDevices",
            ["sh", "-c", "exec razer-battery"],
            (stdout, exitCode) => {
                const level = String(stdout || "").trim();
                if (exitCode === 1 || exitCode === 127) {
                    root.razerDevices = [];
                } else if (exitCode === 2 || (exitCode === 0 && /^(100|[1-9]?\d)%$/.test(level))) {
                    root.razerDevices = [{
                        "name": "Razer Naga V2 HyperSpeed",
                        "type": "mouse",
                        "percentage": exitCode === 0 ? parseInt(level, 10) : null,
                        "status": exitCode === 2 ? "No connection" : "",
                        "lowThreshold": 10
                    }];
                } else {
                    root.razerErrorText = exitCode === 124
                        ? "Razer battery refresh timed out."
                        : "Could not read Razer battery status.";
                    root.finishRazerRefresh();
                    return;
                }
                root.razerUpdatedAt = Date.now();
                root.finishRazerRefresh();
            },
            0,
            30000
        );
        return true;
    }

    function parseAsusPayload(stdout) {
        let payload = null;
        try {
            payload = JSON.parse(String(stdout || "").trim());
        } catch (error) {
            return null;
        }
        if (!payload || typeof payload.available !== "boolean"
                || typeof payload.path !== "string"
                || !Array.isArray(payload.devices)) {
            return null;
        }

        const devices = [];
        for (const device of payload.devices) {
            if (!device || !isFinite(device.percentage))
                return null;
            devices.push({
                "name": String(device.name || "ASUS ROG Chakram X"),
                "type": String(device.type || "mouse").toLowerCase(),
                "percentage": Math.max(0, Math.min(100, Math.round(device.percentage))),
                "charging": device.charging === true,
                "lowThreshold": Math.max(0, Math.min(100, Math.round(device.lowThreshold || 0)))
            });
        }
        payload.devices = devices;
        return payload;
    }

    function finishAsusRefresh() {
        const completedDiscovery = asusDiscovering;
        asusRefreshing = false;
        asusDiscovering = false;
        publishPeripheralState();

        if (asusDiscoveryPending) {
            asusDiscoveryPending = false;
            asusRefreshPending = false;
            Qt.callLater(() => root.discoverAsus());
            return;
        }
        if (completedDiscovery)
            asusRefreshPending = false;
        if (!asusRefreshPending)
            return;
        asusRefreshPending = false;
        Qt.callLater(() => root.refreshAsus());
    }

    function runAsus(discovering) {
        if (asusRefreshing) {
            if (discovering && !asusDiscovering)
                asusDiscoveryPending = true;
            else if (!discovering && !asusDiscovering)
                asusRefreshPending = true;
            return false;
        }
        if (!discovering && (!asusDeviceAvailable || !asusDevicePath))
            return false;

        asusRefreshing = true;
        asusDiscovering = discovering;
        asusErrorText = "";
        publishPeripheralState();

        const command = discovering
            ? [asusHelperPath, "discover"]
            : [asusHelperPath, "read", asusDevicePath];
        Proc.runCommand(
            discovering ? "batteryHub.discoverAsus" : "batteryHub.refreshAsus",
            command,
            (stdout, exitCode) => {
                const payload = root.parseAsusPayload(stdout);
                if (discovering)
                    root.asusAvailabilityKnown = true;

                if (!payload) {
                    root.asusErrorText = "ASUS battery helper returned invalid data.";
                    root.finishAsusRefresh();
                    return;
                }

                root.asusDeviceAvailable = payload.available;
                root.asusDevicePath = payload.available ? payload.path : "";
                if (!payload.available) {
                    root.asusDevices = [];
                } else if (exitCode === 0) {
                    root.asusDevices = payload.devices;
                    if (payload.devices.length > 0)
                        root.asusUpdatedAt = Date.now();
                }

                root.asusErrorText = String(payload.error || "");
                if (exitCode !== 0 && !root.asusErrorText) {
                    root.asusErrorText = exitCode === 124
                        ? "ASUS battery refresh timed out."
                        : "Could not read ASUS battery status.";
                }
                root.finishAsusRefresh();
            },
            0,
            10000
        );
        return true;
    }

    function discoverAsus() {
        return runAsus(true);
    }

    function refreshAsus() {
        return runAsus(false);
    }

    function discoverPeripherals() {
        const razerStarted = refreshRazer();
        const asusStarted = discoverAsus();
        const zmkStarted = discoverZmk();
        return razerStarted || asusStarted || zmkStarted;
    }

    function refreshPeripherals() {
        const razerStarted = razerDeviceAvailable && refreshRazer();
        const asusStarted = refreshAsus();
        return razerStarted || asusStarted || zmkState.available;
    }

    function drainRefreshQueue() {
        if (!refreshPending || busy)
            return;
        refreshPending = false;
        Qt.callLater(() => root.refresh());
    }

    function checkAvailability() {
        if (checkingAvailability)
            return false;

        checkingAvailability = true;
        publishState();

        Proc.runCommand(
            "batteryHub.checkAvailability",
            ["sh", "-c", "command -v ideapad-cm >/dev/null 2>&1"],
            (_stdout, exitCode) => {
                root.commandAvailable = exitCode === 0;
                root.availabilityKnown = true;
                root.checkingAvailability = false;

                if (!root.commandAvailable) {
                    root.modeKnown = false;
                    root.errorText = "";
                    root.publishState();
                    return;
                }

                root.publishState();
                root.refresh();
            },
            0,
            10000
        );
        return true;
    }

    function runStatus(showError, onDone) {
        if (!commandAvailable)
            return false;
        if (busy) {
            refreshPending = true;
            return false;
        }

        refreshing = true;
        errorText = "";
        publishState();

        Proc.runCommand(
            "batteryHub.status",
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
        if (!commandAvailable || busy)
            return false;

        targetEnabled = enabled;
        changing = true;
        errorText = "";
        publishState();

        Proc.runCommand(
            "batteryHub.change",
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
        if (!commandAvailable || busy)
            return false;

        return runStatus(true, ok => {
            if (ok)
                root.setMode(!root.modeEnabled);
        });
    }

    Component.onCompleted: {
        publishState();
        publishPeripheralState();
        checkAvailability();
        discoverPeripherals();
    }
    Component.onDestruction: shuttingDown = true

    Process {
        id: zmkReader

        onExited: (exitCode, exitStatus) => {
            if (root.shuttingDown)
                return;
            if (root.zmkRestartPending) {
                Qt.callLater(() => root.startZmkReader());
            } else {
                root.clearZmk("ZMK battery reader stopped. Refresh to retry.");
            }
        }
        stdout: SplitParser {
            onRead: line => {
                if (root.zmkRestartPending || root.shuttingDown)
                    return;
                try {
                    const state = JSON.parse(line);
                    if (typeof state.available !== "boolean" || !Array.isArray(state.devices)
                            || !Array.isArray(state.barDevices) || typeof state.error !== "string")
                        throw new Error("Invalid ZMK state");
                    root.acceptZmkState(state);
                } catch (error) {
                    root.clearZmk("ZMK battery reader returned invalid data.");
                }
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("Battery Hub ZMK:", line)
        }
    }

    Timer {
        interval: 900000
        repeat: true
        running: root.commandAvailable
        onTriggered: root.refresh()
    }

    Timer {
        interval: 900000
        repeat: true
        running: root.razerDeviceAvailable
        onTriggered: root.refreshRazer()
    }

    Timer {
        interval: 900000
        repeat: true
        running: root.asusDeviceAvailable
        onTriggered: root.refreshAsus()
    }

    IpcHandler {
        target: "battery-hub-conservation"

        function discover(): string {
            return root.checkAvailability() ? "DISCOVERY_STARTED" : "BUSY";
        }

        function refresh(): string {
            if (!root.commandAvailable)
                return "UNAVAILABLE";
            return root.refresh() ? "REFRESH_STARTED" : "REFRESH_QUEUED";
        }

        function enable(): string {
            if (!root.commandAvailable)
                return "UNAVAILABLE";
            return root.setMode(true) ? "ENABLE_STARTED" : "BUSY";
        }

        function disable(): string {
            if (!root.commandAvailable)
                return "UNAVAILABLE";
            return root.setMode(false) ? "DISABLE_STARTED" : "BUSY";
        }

        function toggle(): string {
            if (!root.commandAvailable)
                return "UNAVAILABLE";
            return root.toggleMode() ? "TOGGLE_STARTED" : "BUSY";
        }

        function status(): string {
            if (root.errorText)
                return "error\t" + root.errorText;
            return root.statusText();
        }
    }

    IpcHandler {
        target: "battery-hub-devices"

        function discover(): string {
            return root.discoverPeripherals() ? "DISCOVERY_STARTED" : "BUSY";
        }

        function refresh(): string {
            if (!root.razerDeviceAvailable && !root.asusDeviceAvailable && !root.zmkState.available)
                return "UNAVAILABLE";
            return root.refreshPeripherals() ? "REFRESH_STARTED" : "REFRESH_QUEUED";
        }

        function status(): string {
            const error = root.peripheralErrorText();
            if (error)
                return "error\t" + error;
            if (!root.razerDeviceAvailable && !root.asusDeviceAvailable && !root.zmkState.available)
                return "UNAVAILABLE";
            return (root.razerDevices.length + root.asusDevices.length + root.zmkState.devices.length)
                + " battery device(s)";
        }

        function zmk(): string {
            return JSON.stringify(root.zmkState);
        }
    }
}
