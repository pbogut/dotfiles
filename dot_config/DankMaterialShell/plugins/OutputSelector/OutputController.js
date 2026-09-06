// Kept independent of QML so switching can be tested without real displays.
function createController(io, initialMode) {
    var mode = initialMode === "single" ? "single" : "multiple";
    var outputs = {};
    var selected = "";
    var topology = "";
    var topologyPending = false;
    var error = "";
    var job = null;
    var disposed = false;

    function names() {
        return Object.keys(outputs).sort();
    }

    function enabled(name) {
        var output = outputs[name];
        return !!output && output.current_mode !== null
                && output.current_mode !== undefined && !!output.logical;
    }

    function active() {
        return names().filter(enabled);
    }

    function fallback(candidates) {
        return candidates.find(function (name) { return /^(eDP|LVDS|DSI)-/.test(name); })
                || candidates[0] || "";
    }

    function publish() {
        if (disposed)
            return;
        io.publish({
            mode: mode,
            busy: job !== null,
            error: error,
            outputs: names().map(function (name) {
                var output = outputs[name];
                var current = (output.modes || [])[output.current_mode];
                return {
                    name: name,
                    label: output.model || output.make || name,
                    enabled: enabled(name),
                    internal: /^(eDP|LVDS|DSI)-/.test(name),
                    detail: enabled(name) && current
                            ? current.width + "x" + current.height + " @ "
                              + Math.round(current.refresh_rate / 1000) + " Hz"
                            : "Off"
                };
            })
        });
    }

    function store(value) {
        var previouslyActive = active().length;
        outputs = value;
        var nextTopology = JSON.stringify(names());
        if (topology !== nextTopology || (previouslyActive > 0 && active().length === 0))
            topologyPending = true;
        topology = nextTopology;
        publish();
    }

    function start(kind, target, turnOn, nextMode, preserveError) {
        job = {kind: kind, target: target, turnOn: turnOn, nextMode: nextMode,
            waiting: null, confirmed: false, deadline: io.now() + 15000};
        if (!preserveError)
            error = "";
        publish();
        step();
    }

    function finish(message, allowRecovery) {
        var finished = job;
        if (message) {
            error = message;
        } else if (finished.kind === "single") {
            selected = finished.target;
            if (finished.nextMode && mode !== finished.nextMode) {
                mode = finished.nextMode;
                if (!io.saveMode(mode))
                    error = "Outputs changed, but the mode could not be saved.";
            }
        }
        if (mode === "single" && active().length
                && (finished.kind === "recover" || !enabled(selected)))
            selected = fallback(active());
        job = null;
        publish();

        // A cable can disappear between the final safety check and an off command.
        if (allowRecovery && finished.kind !== "recover" && names().length && !active().length) {
            topologyPending = false;
            start("recover", fallback(names()), true, null, true);
        } else if (!message || (allowRecovery && mode === "single" && enabled(selected) && topologyPending)) {
            reconcile(!!message);
        } else {
            topologyPending = false;
        }
    }

    function step() {
        var current = job;
        if (!current || disposed)
            return;
        io.read(function (message, value) {
            if (disposed || job !== current)
                return;
            if (message) {
                finish(message, false);
                return;
            }
            store(value);
            if (io.now() >= current.deadline) {
                finish("Timed out waiting for the monitor change.", true);
                return;
            }

            if (current.waiting) {
                var waiting = current.waiting;
                if (waiting.on && !outputs[waiting.name]) {
                    finish("The selected monitor was disconnected.", true);
                    return;
                }
                if (enabled(waiting.name) !== waiting.on) {
                    io.later(step);
                    return;
                }
                current.waiting = null;
            }

            var target = current.target;
            var turnOn = current.turnOn;
            if (current.kind === "recover" && active().length) {
                finish("", false);
                return;
            }
            if (!outputs[target]) {
                finish("The selected monitor was disconnected.", true);
                return;
            }
            if (current.kind === "single") {
                if (!enabled(target)) {
                    if (current.confirmed) {
                        finish("The selected monitor is no longer active.", true);
                        return;
                    }
                    turnOn = true;
                } else {
                    current.confirmed = true;
                    target = active().find(function (name) { return name !== current.target; });
                    turnOn = false;
                    if (!target) {
                        finish("", true);
                        return;
                    }
                }
            } else if (enabled(target) === turnOn) {
                finish("", true);
                return;
            }

            if (!turnOn && active().length <= 1) {
                finish("Keep at least one monitor on.", true);
                return;
            }
            current.waiting = {name: target, on: turnOn};
            io.change(target, turnOn, function (failure) {
                if (disposed || job !== current)
                    return;
                if (!failure) {
                    io.later(step);
                    return;
                }
                // Refresh even on failure: a timed-out command may have taken effect.
                io.read(function (readError, latest) {
                    if (disposed || job !== current)
                        return;
                    if (!readError)
                        store(latest);
                    finish(failure, !readError);
                });
            });
        });
    }

    function reconcile(preserveError) {
        if (disposed || job || !topologyPending || !names().length)
            return;
        topologyPending = false;
        var live = active();
        if (mode === "single") {
            if (!outputs[selected]) {
                var focused = io.focused();
                selected = selected ? fallback(names())
                        : (enabled(focused) ? focused : fallback(live.length ? live : names()));
            }
            start("single", selected, true, null, preserveError);
        } else if (!live.length) {
            start("recover", fallback(names()), true, null, false);
        }
    }

    return {
        observe: function (value) {
            if (disposed)
                return;
            store(value);
            reconcile();
        },
        select: function (name) {
            if (disposed || job || !outputs[name])
                return false;
            start(mode === "single" ? "single" : "toggle", name, !enabled(name), null, false);
            return true;
        },
        setMode: function (value, screen) {
            if (disposed || job || (value !== "single" && value !== "multiple"))
                return false;
            if (value === mode)
                return true;
            if (value === "multiple") {
                if (!io.saveMode(value)) {
                    error = "The mode could not be saved.";
                    publish();
                    return false;
                }
                mode = value;
                error = "";
                publish();
                return true;
            }
            if (!outputs[screen])
                return false;
            start("single", screen, true, value, false);
            return true;
        },
        dispose: function () { disposed = true; }
    };
}
