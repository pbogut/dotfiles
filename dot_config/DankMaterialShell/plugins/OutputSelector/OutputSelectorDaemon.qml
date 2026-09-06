import "OutputController.js" as Controller
import QtQuick
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services

PluginComponent {
    id: root

    readonly property bool supported: CompositorService.isNiri
    property var controller: null
    property var delayedStep: null
    property var snapshotData: ({
        "mode": "multiple",
        "outputs": [],
        "busy": false,
        "error": ""
    })

    function publish(snapshot) {
        const previousError = snapshotData.error;
        snapshotData = snapshot;
        if (pluginService && pluginId)
            pluginService.setGlobalVar(pluginId, "snapshot", snapshot);

        if (snapshot.error && snapshot.error !== previousError)
            ToastService.showError("Output Selector", snapshot.error);

    }

    function readOutputs(done) {
        if (!supported) {
            done("Output Selector requires niri.");
            return ;
        }
        Proc.runCommand(null, ["niri", "msg", "-j", "outputs"], (stdout, exitCode) => {
            if (exitCode !== 0) {
                done("Could not read niri outputs.");
                return ;
            }
            let outputs;
            try {
                outputs = JSON.parse(stdout);
                if (!outputs || typeof outputs !== "object" || Array.isArray(outputs) || !Object.keys(outputs).every((name) => {
                    const output = outputs[name];
                    return output && output.name === name && Array.isArray(output.modes) && (output.current_mode === null || Number.isInteger(output.current_mode)) && (output.logical === null || typeof output.logical === "object");
                }))
                    throw new Error("Invalid output inventory");

            } catch (error) {
                done("Niri returned invalid output data.");
                return ;
            }
            done(null, outputs);
        }, 0, 3000);
    }

    function initialize() {
        if (controller || !supported || !pluginService || !pluginId)
            return ;

        controller = Controller.createController({
            "now": () => {
                return Date.now();
            },
            "focused": () => {
                return NiriService.currentOutput;
            },
            "publish": (snapshot) => {
                return root.publish(snapshot);
            },
            "saveMode": (mode) => {
                return root.pluginService.savePluginData(root.pluginId, "mode", mode);
            },
            "read": (done) => {
                return root.readOutputs(done);
            },
            "later": (callback) => {
                root.delayedStep = callback;
                stepTimer.restart();
            },
            "change": (name, turnOn, done) => {
                Proc.runCommand(null, ["niri", "msg", "output", name, turnOn ? "on" : "off"], (_stdout, exitCode) => {
                    done(exitCode === 0 ? null : "Could not turn " + name + (turnOn ? " on." : " off."));
                }, 0, 3000);
            }
        }, pluginService.loadPluginData(pluginId, "mode", "multiple"));
        refresh();
    }

    function refresh() {
        if (!controller || snapshotData.busy)
            return ;

        readOutputs((error, outputs) => {
            if (error) {
                root.publish(Object.assign({
                }, root.snapshotData, {
                    "error": error
                }));
                return ;
            }
            root.controller.observe(outputs);
        });
    }

    function selectOutput(name) {
        return supported && controller ? controller.select(name) : false;
    }

    function setMode(mode, screen) {
        return supported && controller ? controller.setMode(mode, screen) : false;
    }

    Component.onCompleted: initialize()
    Component.onDestruction: {
        if (controller)
            controller.dispose();

    }
    onSupportedChanged: Qt.callLater(initialize)

    Connections {
        function onOutputsChanged() {
            if (root.supported && root.controller)
                root.controller.observe(NiriService.outputs);

        }

        target: NiriService
    }

    Timer {
        id: stepTimer

        interval: 100
        onTriggered: {
            const callback = root.delayedStep;
            root.delayedStep = null;
            if (callback)
                callback();

        }
    }

    IpcHandler {
        function status() : string {
            return JSON.stringify(Object.assign({
                "supported": root.supported
            }, root.snapshotData));
        }

        target: "output-selector"
    }

}
