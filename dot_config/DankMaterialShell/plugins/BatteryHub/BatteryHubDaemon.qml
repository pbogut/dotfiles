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
    property bool razerAvailabilityKnown: false
    property bool razerCommandAvailable: false
    property bool razerCheckingAvailability: false
    property bool razerRefreshing: false
    property bool razerRefreshPending: false
    property var razerDevices: []
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
        return errors.join(" ");
    }

    function publishPeripheralState() {
        if (!pluginService || !pluginId)
            return;

        pluginService.setGlobalVar(pluginId, "peripheralBatteries", {
            "available": (razerAvailabilityKnown && razerCommandAvailable)
                || (asusAvailabilityKnown && asusDeviceAvailable),
            "devices": razerDevices.concat(asusDevices),
            "refreshing": razerCheckingAvailability || razerRefreshing || asusRefreshing,
            "error": peripheralErrorText(),
            "updatedAt": Math.max(razerUpdatedAt, asusUpdatedAt)
        });
    }

    function parseRazerDevices(stdout) {
        const devices = [];
        const lines = String(stdout || "").split(/\r?\n/);
        let current = null;
        let inBattery = false;

        function appendCurrent() {
            if (!current || !current.hasBattery || !isFinite(current.percentage))
                return;

            devices.push({
                "name": current.name,
                "type": current.type || "device",
                "percentage": Math.max(0, Math.min(100, Math.round(current.percentage))),
                "charging": current.charging,
                "lowThreshold": Math.max(0, Math.min(100, Math.round(current.lowThreshold)))
            });
        }

        for (const line of lines) {
            const deviceMatch = line.match(/^([^\s].*):\s*$/);
            if (deviceMatch) {
                appendCurrent();
                current = {
                    "name": deviceMatch[1].trim(),
                    "type": "",
                    "hasBattery": false,
                    "percentage": NaN,
                    "charging": false,
                    "lowThreshold": 0
                };
                inBattery = false;
                continue;
            }
            if (!current)
                continue;

            const trimmed = line.trim();
            const separator = trimmed.indexOf(":");
            if (separator < 0)
                continue;

            const indentMatch = line.match(/^\s*/);
            const indent = indentMatch ? indentMatch[0].length : 0;
            const key = trimmed.slice(0, separator).trim().toLowerCase();
            const value = trimmed.slice(separator + 1).trim();

            if (indent <= 4) {
                inBattery = key === "battery";
                if (key === "type")
                    current.type = value.toLowerCase();
                if (inBattery)
                    current.hasBattery = true;
                continue;
            }
            if (!inBattery)
                continue;

            if (key === "charge") {
                current.percentage = Number(value);
            } else if (key === "charging") {
                current.charging = value.toLowerCase() === "true";
            } else if (key === "low threshold") {
                current.lowThreshold = Number(value.split(/\s+/)[0]);
            }
        }

        appendCurrent();
        return devices;
    }

    function checkRazerAvailability() {
        if (razerCheckingAvailability)
            return false;

        razerCheckingAvailability = true;
        publishPeripheralState();

        Proc.runCommand(
            "batteryHub.checkRazerAvailability",
            ["sh", "-c", "command -v razer-cli >/dev/null 2>&1"],
            (_stdout, exitCode) => {
                root.razerCommandAvailable = exitCode === 0;
                root.razerAvailabilityKnown = true;
                root.razerCheckingAvailability = false;

                if (!root.razerCommandAvailable) {
                    root.razerDevices = [];
                    root.razerErrorText = "";
                    root.publishPeripheralState();
                    return;
                }

                root.publishPeripheralState();
                root.refreshRazer();
            },
            0,
            10000
        );
        return true;
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
        if (!razerCommandAvailable)
            return false;
        if (razerRefreshing) {
            razerRefreshPending = true;
            return false;
        }

        razerRefreshing = true;
        razerErrorText = "";
        publishPeripheralState();

        Proc.runCommand(
            "batteryHub.razerDevices",
            ["razer-cli", "-ls"],
            (stdout, exitCode) => {
                if (exitCode !== 0) {
                    root.razerErrorText = exitCode === 124
                        ? "Razer battery refresh timed out."
                        : "Could not read Razer battery status.";
                    root.finishRazerRefresh();
                    return;
                }
                if (!/^Found\s+\d+\s+Razer device\(s\)/m.test(String(stdout || ""))) {
                    root.razerErrorText = "razer-cli returned an unknown device list.";
                    root.finishRazerRefresh();
                    return;
                }

                root.razerDevices = root.parseRazerDevices(stdout);
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
        const razerStarted = checkRazerAvailability();
        const asusStarted = discoverAsus();
        return razerStarted || asusStarted;
    }

    function refreshPeripherals() {
        const razerStarted = refreshRazer();
        const asusStarted = refreshAsus();
        return razerStarted || asusStarted;
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

    Timer {
        interval: 900000
        repeat: true
        running: root.commandAvailable
        onTriggered: root.refresh()
    }

    Timer {
        interval: 900000
        repeat: true
        running: root.razerCommandAvailable
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
            if (!root.razerCommandAvailable && !root.asusDeviceAvailable)
                return "UNAVAILABLE";
            return root.refreshPeripherals() ? "REFRESH_STARTED" : "REFRESH_QUEUED";
        }

        function status(): string {
            if (!root.razerCommandAvailable && !root.asusDeviceAvailable)
                return "UNAVAILABLE";
            const error = root.peripheralErrorText();
            if (error)
                return "error\t" + error;
            return (root.razerDevices.length + root.asusDevices.length)
                + " battery device(s)";
        }
    }
}
