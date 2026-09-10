const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { resolve } = require("node:path");
const { test } = require("node:test");
const { runInNewContext } = require("node:vm");

const source = readFileSync(resolve(__dirname, "../OutputController.js"), "utf8");
const { createController } = runInNewContext(source + ";({createController})");
const copy = value => JSON.parse(JSON.stringify(value));

function output(name, on = true) {
    return {name, model: name, current_mode: on ? 0 : null,
        logical: on ? {x: 0, y: 0} : null,
        modes: [{width: 1920, height: 1080, refresh_rate: 60000}]};
}

function setup(mode = "multiple", initial = [output("eDP-1"), output("DP-1")]) {
    const env = {outputs: Object.fromEntries(initial.map(item => [item.name, item])),
        commands: [], saved: [], queue: [], now: 0, snapshot: null};
    const io = {
        now: () => env.now,
        focused: () => "eDP-1",
        publish: value => { env.snapshot = copy(value); },
        saveMode: value => { env.saved.push(value); return true; },
        read: done => done(null, copy(env.outputs)),
        readFocus: done => done(null, {workspaces: [], windows: []}),
        focus: () => true,
        later: callback => env.queue.push(callback),
        change: (name, on, done) => {
            env.commands.push([name, on]);
            env.outputs[name] = output(name, on);
            done(null);
        }
    };
    env.io = io;
    env.controller = createController(io, mode);
    env.observe = () => env.controller.observe(copy(env.outputs));
    env.drain = () => {
        let iterations = 0;
        while (env.queue.length) {
            assert.ok(++iterations < 300, "controller did not settle");
            env.now += 100;
            env.queue.shift()();
        }
    };
    env.observe();
    return env;
}

test("defaults to multiple without changing outputs, including mode index zero", () => {
    const env = setup();
    assert.deepEqual(env.commands, []);
    assert.equal(env.snapshot.outputs.filter(item => item.enabled).length, 2);
});

test("entering single keeps the clicked bar's monitor and saves the mode", () => {
    const env = setup();
    env.controller.setMode("single", "DP-1");
    env.drain();
    assert.deepEqual(env.commands, [["eDP-1", false]]);
    assert.deepEqual(env.saved, ["single"]);
    assert.equal(env.snapshot.mode, "single");
});

test("single selection enables and confirms the new output before disabling the old", () => {
    const env = setup("single", [output("eDP-1"), output("DP-1", false)]);
    env.controller.select("DP-1");
    assert.deepEqual(env.commands, [["DP-1", true]]);
    env.drain();
    assert.deepEqual(env.commands, [["DP-1", true], ["eDP-1", false]]);
    env.controller.select("DP-1");
    assert.equal(env.commands.length, 2);
});

test("multiple permits independent toggles but refuses to disable the last output", () => {
    const env = setup();
    env.controller.select("DP-1");
    env.drain();
    env.controller.select("eDP-1");
    assert.deepEqual(env.commands, [["DP-1", false]]);
    assert.match(env.snapshot.error, /at least one/);
    env.controller.select("DP-1");
    env.drain();
    assert.equal(env.snapshot.outputs.filter(item => item.enabled).length, 2);
});

test("entering multiple does not enable previously disabled outputs", () => {
    const env = setup("single", [output("eDP-1"), output("DP-1", false)]);
    env.controller.setMode("multiple", "eDP-1");
    assert.deepEqual(env.commands, []);
    assert.deepEqual(env.saved, ["multiple"]);
});

test("single hotplug keeps current selection and includes disabled connectors", () => {
    const env = setup("single", [output("eDP-1")]);
    env.outputs["DP-1"] = output("DP-1");
    env.observe();
    env.drain();
    assert.deepEqual(env.commands, [["DP-1", false]]);
    assert.equal(env.snapshot.outputs.length, 2);
});

test("unplugging the selected output restores the internal display", () => {
    const env = setup("single", [output("eDP-1", false), output("DP-1")]);
    delete env.outputs["DP-1"];
    env.observe();
    env.drain();
    assert.deepEqual(env.commands, [["eDP-1", true]]);
});

test("failed activation preserves the old display and does not loop", () => {
    const env = setup("single", [output("eDP-1"), output("DP-1", false)]);
    env.io.change = (name, on, done) => {
        env.commands.push([name, on]);
        done("Activation failed");
    };
    env.controller.select("DP-1");
    env.drain();
    assert.deepEqual(env.commands, [["DP-1", true]]);
    assert.match(env.snapshot.error, /Activation failed/);
    assert.equal(env.outputs["eDP-1"].current_mode, 0);
});

test("successful command without confirmed activation times out safely", () => {
    const env = setup("single", [output("eDP-1"), output("DP-1", false)]);
    env.io.change = (name, on, done) => { env.commands.push([name, on]); done(null); };
    env.controller.select("DP-1");
    env.drain();
    assert.deepEqual(env.commands, [["DP-1", true]]);
    assert.match(env.snapshot.error, /Timed out/);
    assert.equal(env.snapshot.busy, false);
});

test("unplug between safety check and off command recovers a remaining display", () => {
    const env = setup("single", [output("eDP-1"), output("DP-1", false)]);
    const change = env.io.change;
    env.io.change = (name, on, done) => {
        if (name === "eDP-1" && !on)
            delete env.outputs["DP-1"];
        change(name, on, done);
    };
    env.controller.select("DP-1");
    env.drain();
    assert.deepEqual(env.commands, [["DP-1", true], ["eDP-1", false], ["eDP-1", true]]);
    assert.match(env.snapshot.error, /disconnected/);
});

test("busy operations reject overlapping clicks and disconnected targets", () => {
    const env = setup();
    assert.equal(env.controller.select("missing"), false);
    env.controller.select("DP-1");
    assert.equal(env.controller.select("eDP-1"), false);
    assert.equal(env.controller.setMode("single", "eDP-1"), false);
    env.drain();
});

test("a read failure never issues an output command", () => {
    const env = setup();
    env.io.read = done => done("Niri unavailable");
    env.controller.select("DP-1");
    assert.deepEqual(env.commands, []);
    assert.equal(env.snapshot.error, "Niri unavailable");
});

test("disposed controllers ignore pending callbacks", () => {
    const env = setup("single", [output("eDP-1"), output("DP-1", false)]);
    env.controller.select("DP-1");
    env.controller.dispose();
    env.drain();
    assert.deepEqual(env.commands, [["DP-1", true]]);
});

test("single selection handles more than two monitors", () => {
    const env = setup("multiple", [output("eDP-1"), output("DP-1"), output("DP-2")]);
    env.controller.setMode("single", "DP-2");
    env.drain();
    assert.deepEqual(env.commands, [["DP-1", false], ["eDP-1", false]]);
    assert.equal(env.snapshot.outputs.filter(item => item.enabled)[0].name, "DP-2");
});

test("a hotplug during switching is reconciled without overlapping operations", () => {
    const env = setup("single", [output("eDP-1"), output("DP-1", false)]);
    env.controller.select("DP-1");
    env.outputs["DP-2"] = output("DP-2");
    env.observe();
    env.drain();
    assert.equal(env.snapshot.outputs.filter(item => item.enabled).length, 1);
    assert.equal(env.snapshot.outputs.find(item => item.name === "DP-1").enabled, true);
});

test("startup restores single mode using the focused active output", () => {
    const env = setup("single");
    env.drain();
    assert.deepEqual(env.commands, [["DP-1", false]]);
    assert.deepEqual(env.saved, []);
});

test("empty initial inventory does not erase the remembered mode", () => {
    const env = setup("single", []);
    assert.deepEqual(env.commands, []);
    env.outputs = {"eDP-1": output("eDP-1"), "DP-1": output("DP-1")};
    env.observe();
    env.drain();
    assert.equal(env.snapshot.mode, "single");
    assert.deepEqual(env.commands, [["DP-1", false]]);
});

test("failed entry into single mode does not persist a mode change", () => {
    const env = setup();
    env.io.change = (_name, _on, done) => done("Could not disable output");
    env.controller.setMode("single", "DP-1");
    assert.deepEqual(env.saved, []);
    assert.equal(env.snapshot.mode, "multiple");
    assert.match(env.snapshot.error, /Could not disable/);
});

test("settings write failure is reported", () => {
    const env = setup("single", [output("eDP-1")]);
    env.io.saveMode = () => false;
    assert.equal(env.controller.setMode("multiple", "eDP-1"), false);
    assert.equal(env.snapshot.mode, "single");
    assert.match(env.snapshot.error, /could not be saved/);
});

test("failed recovery stops instead of retrying forever", () => {
    const env = setup("multiple", [output("eDP-1")]);
    env.io.change = (name, on, done) => {
        env.commands.push([name, on]);
        done("Could not enable output");
    };
    env.outputs["eDP-1"] = output("eDP-1", false);
    env.observe();
    env.observe();
    env.drain();
    assert.deepEqual(env.commands, [["eDP-1", true]]);
    assert.equal(env.snapshot.busy, false);
});

test("hotplug after recovery keeps the recovered display, not the old selection", () => {
    const env = setup("single", [output("eDP-1", false), output("DP-1"), output("DP-2", false)]);
    const change = env.io.change;
    env.io.change = (name, on, done) => {
        if (name === "DP-1" && !on)
            delete env.outputs["DP-2"];
        change(name, on, done);
    };
    env.controller.select("DP-2");
    env.drain();
    env.outputs["DP-3"] = output("DP-3");
    env.observe();
    env.drain();
    assert.deepEqual(env.commands, [["DP-2", true], ["DP-1", false], ["eDP-1", true], ["DP-3", false]]);
    assert.equal(env.snapshot.outputs.filter(item => item.enabled)[0].name, "eDP-1");
});

test("hotplug during failed activation still keeps the current output", () => {
    const env = setup("single", [output("eDP-1"), output("DP-1", false)]);
    const change = env.io.change;
    let complete;
    env.io.change = (name, on, done) => { env.commands.push([name, on]); complete = done; };
    env.controller.select("DP-1");
    env.outputs["DP-2"] = output("DP-2");
    env.observe();
    env.io.change = change;
    complete("Activation failed");
    env.drain();
    assert.deepEqual(env.commands, [["DP-1", true], ["DP-2", false]]);
    assert.match(env.snapshot.error, /Activation failed/);
    assert.equal(env.snapshot.outputs.filter(item => item.enabled)[0].name, "eDP-1");
});

test("a failed-but-applied switch retains the actually active output on hotplug", () => {
    const env = setup("single", [output("eDP-1"), output("DP-1", false)]);
    const change = env.io.change;
    env.io.change = (name, on, done) => {
        change(name, on, () => done(!on ? "Command timed out" : null));
    };
    env.controller.select("DP-1");
    env.drain();
    env.io.change = change;
    env.outputs["DP-2"] = output("DP-2");
    env.observe();
    env.drain();
    assert.deepEqual(env.commands, [["DP-1", true], ["eDP-1", false], ["DP-2", false]]);
});

test("cycle visits disabled monitors in connector order and wraps around", () => {
    const env = setup("single", [output("eDP-1"), output("DP-2", false), output("DP-1", false)]);
    for (const name of ["DP-1", "DP-2", "eDP-1"]) {
        assert.equal(env.controller.cycle(), true);
        assert.deepEqual(env.commands.at(-1), [name, true]);
        env.drain();
        assert.deepEqual(env.snapshot.outputs.filter(item => item.enabled).map(item => item.name), [name]);
    }
    assert.deepEqual(env.commands, [
        ["DP-1", true], ["eDP-1", false],
        ["DP-2", true], ["DP-1", false],
        ["eDP-1", true], ["DP-2", false]
    ]);
});

test("cycle from multiple advances from focus and saves single mode after success", () => {
    const env = setup("multiple", [output("eDP-1"), output("DP-1"), output("DP-2", false)]);
    env.io.focused = () => "DP-1";
    env.controller.cycle();
    assert.deepEqual(env.saved, []);
    assert.equal(env.snapshot.mode, "multiple");
    env.drain();
    assert.deepEqual(env.commands, [["DP-2", true], ["DP-1", false], ["eDP-1", false]]);
    assert.deepEqual(env.saved, ["single"]);
    assert.equal(env.snapshot.mode, "single");
});

test("cycle uses fresh inventory rather than stale selection or focus", () => {
    const env = setup("single", [output("eDP-1"), output("DP-1", false)]);
    env.outputs = {"eDP-1": output("eDP-1", false), "DP-1": output("DP-1"), "DP-2": output("DP-2", false)};
    env.controller.cycle();
    env.drain();
    assert.deepEqual(env.commands, [["DP-2", true], ["DP-1", false]]);
});

test("cycle rejects overlapping requests even while the initial read is pending", () => {
    const env = setup();
    let completeRead;
    const read = env.io.read;
    env.io.read = done => { completeRead = done; };
    assert.equal(env.controller.cycle(), true);
    assert.equal(env.controller.cycle(), false);
    assert.equal(env.controller.select("DP-1"), false);
    env.io.read = read;
    completeRead(null, copy(env.outputs));
    env.drain();
    assert.equal(env.snapshot.busy, false);
    env.controller.dispose();
    assert.equal(env.controller.cycle(), false);
});

test("cycle keeps a sole monitor on and remembers single mode", () => {
    const env = setup("multiple", [output("eDP-1")]);
    env.controller.cycle();
    assert.deepEqual(env.commands, []);
    assert.deepEqual(env.saved, ["single"]);
});

test("cycle enables a sole disabled monitor using fresh state", () => {
    const env = setup("multiple", [output("eDP-1")]);
    env.outputs["eDP-1"] = output("eDP-1", false);
    env.controller.cycle();
    env.drain();
    assert.deepEqual(env.commands, [["eDP-1", true]]);
    assert.deepEqual(env.saved, ["single"]);
});

test("cycle with no connected monitors does not change the mode or outputs", () => {
    const env = setup("multiple", []);
    env.controller.cycle();
    assert.deepEqual(env.commands, []);
    assert.deepEqual(env.saved, []);
    assert.equal(env.snapshot.busy, false);
    assert.equal(env.snapshot.error, "");
});

test("failed cycle activation keeps the current monitor and saved mode", () => {
    const env = setup("multiple", [output("eDP-1"), output("DP-1", false)]);
    env.io.change = (name, on, done) => {
        env.commands.push([name, on]);
        done("Activation failed");
    };
    env.controller.cycle();
    env.drain();
    assert.deepEqual(env.commands, [["DP-1", true]]);
    assert.deepEqual(env.saved, []);
    assert.equal(env.snapshot.mode, "multiple");
    assert.equal(env.outputs["eDP-1"].current_mode, 0);
    assert.equal(env.snapshot.error, "Activation failed");
});

function withFocus(env, windowId = 42) {
    env.focusState = {
        workspaces: [{id: 7, output: "eDP-1", is_focused: true, active_window_id: windowId}],
        windows: windowId === null ? [] : [{id: windowId, workspace_id: 7, is_focused: true}]
    };
    env.focusRequests = [];
    env.io.readFocus = done => done(null, copy(env.focusState));
    env.io.focus = (workspace, window) => {
        env.focusRequests.push([workspace, window]);
        env.focusState.workspaces.forEach(item => { item.is_focused = item.id === workspace; });
        env.focusState.windows.forEach(item => { item.is_focused = item.id === window; });
        return true;
    };
    const change = env.io.change;
    env.io.change = (name, on, done) => {
        // Activation and shutdown can both change focus. Migration changes indices,
        // but the workspace and window IDs survive.
        env.focusState.workspaces.forEach(item => {
            item.is_focused = false;
            if (!on && item.output === name)
                item.output = Object.keys(env.outputs).find(other => other !== name && env.outputs[other].logical);
        });
        env.focusState.windows.forEach(item => { item.is_focused = false; });
        change(name, on, done);
    };
    return env;
}

test("single switching restores the original window after migration, then verifies focus", () => {
    const env = withFocus(setup("single", [output("eDP-1"), output("DP-1", false)]));
    env.controller.select("DP-1");
    assert.deepEqual(env.focusRequests, []);
    env.drain();
    assert.deepEqual(env.focusRequests, [[7, 42]]);
    assert.equal(env.focusState.workspaces[0].output, "DP-1");
    assert.equal(env.focusState.windows[0].is_focused, true);
    assert.equal(env.snapshot.busy, false);
    assert.equal(env.snapshot.error, "");
});

test("an empty workspace is restored by stable ID", () => {
    const env = withFocus(setup("single", [output("eDP-1"), output("DP-1", false)]), null);
    env.controller.cycle();
    env.drain();
    assert.deepEqual(env.focusRequests, [[7, null]]);
    assert.equal(env.snapshot.error, "");
});

test("a window closed during switching falls back to its workspace", () => {
    const env = withFocus(setup());
    env.controller.setMode("single", "DP-1");
    env.focusState.windows = [];
    env.focusState.workspaces[0].active_window_id = null;
    env.drain();
    assert.deepEqual(env.focusRequests, [[7, null]]);
    assert.deepEqual(env.saved, ["single"]);
});

test("a discarded empty workspace falls back to an empty workspace on the destination", () => {
    const env = withFocus(setup(), null);
    env.controller.setMode("single", "DP-1");
    env.focusState.workspaces = [
        {id: 8, output: "DP-1", is_focused: true, active_window_id: 50},
        {id: 9, output: "DP-1", is_focused: false, active_window_id: null}
    ];
    env.drain();
    assert.deepEqual(env.focusRequests, [[9, null]]);
    assert.equal(env.snapshot.error, "");
});

test("rapid clicks and cycles cannot replace focus during capture, switching, or verification", () => {
    const env = withFocus(setup("single", [output("eDP-1"), output("DP-1", false)]));
    const readFocus = env.io.readFocus;
    let capture;
    env.io.readFocus = done => { capture = done; };
    env.controller.cycle();
    function rejectRequests() {
        assert.equal(env.snapshot.busy, true);
        assert.equal(env.snapshot.preservingFocus, true);
        assert.equal(env.controller.cycle(), false);
        assert.equal(env.controller.select("eDP-1"), false);
        assert.equal(env.controller.setMode("multiple", "DP-1"), false);
    }
    rejectRequests();
    assert.deepEqual(env.commands, []);
    env.io.readFocus = readFocus;
    capture(null, copy(env.focusState));
    rejectRequests();

    const focus = env.io.focus;
    let applyFocus;
    env.io.focus = (workspace, window) => {
        env.focusRequests.push([workspace, window]);
        applyFocus = () => focus(workspace, window);
        return true;
    };
    while (!applyFocus) {
        env.queue.shift()();
        rejectRequests();
    }
    for (let i = 0; i < 4; i++) {
        env.queue.shift()();
        rejectRequests();
    }
    assert.deepEqual(env.focusRequests, [[7, 42]], "focus must be sent only once while it is pending");
    applyFocus();
    rejectRequests(); // Sending/applying focus alone does not release BUSY.
    env.drain();
    assert.equal(env.snapshot.busy, false);
    assert.equal(env.snapshot.error, "");
    assert.equal(env.focusState.windows[0].is_focused, true);
});

test("an immediate next cycle captures fresh focus despite a stale DMS output cache", () => {
    const env = withFocus(setup("single", [output("eDP-1"), output("DP-1", false)]));
    env.controller.cycle();
    env.drain();
    env.focusState.workspaces[0].active_window_id = 84;
    env.focusState.windows = [{id: 84, workspace_id: 7, is_focused: true}];
    assert.equal(env.io.focused(), "eDP-1", "simulate the cache lagging behind niri");
    assert.equal(env.controller.cycle(), true);
    env.drain();
    assert.deepEqual(env.focusRequests, [[7, 42], [7, 84]]);
    assert.equal(env.focusState.workspaces[0].output, "eDP-1");
    assert.equal(env.snapshot.error, "");
});

test("cycle chooses its starting output from the fresh workspace instead of the DMS cache", () => {
    const env = withFocus(setup("multiple", [output("eDP-1"), output("DP-1"), output("DP-2")]));
    env.focusState.workspaces[0].output = "DP-1";
    env.controller.cycle();
    env.drain();
    assert.deepEqual(env.snapshot.outputs.filter(item => item.enabled).map(item => item.name), ["DP-2"]);
    assert.deepEqual(env.focusRequests, [[7, 42]]);
});

test("focus capture failure aborts before any monitor changes", () => {
    const env = withFocus(setup());
    env.io.readFocus = done => done("Could not read niri workspaces.");
    env.controller.cycle();
    assert.deepEqual(env.commands, []);
    assert.deepEqual(env.focusRequests, []);
    assert.equal(env.snapshot.busy, false);
    assert.match(env.snapshot.error, /Could not read/);
});

test("focus restoration waits for workspace migration before sending an action", () => {
    const env = withFocus(setup());
    env.controller.setMode("single", "DP-1");
    env.focusState.workspaces[0].output = "eDP-1";
    env.queue.shift()();
    assert.deepEqual(env.focusRequests, []);
    assert.equal(env.snapshot.busy, true);
    env.focusState.workspaces[0].output = "DP-1";
    env.drain();
    assert.deepEqual(env.focusRequests, [[7, 42]]);
    assert.equal(env.snapshot.error, "");
});

test("unconfirmed focus times out without repeating actions or undoing a successful mode change", () => {
    const env = withFocus(setup());
    env.io.focus = (workspace, window) => { env.focusRequests.push([workspace, window]); return true; };
    env.controller.setMode("single", "DP-1");
    env.drain();
    assert.deepEqual(env.focusRequests, [[7, 42]]);
    assert.deepEqual(env.saved, ["single"]);
    assert.equal(env.snapshot.mode, "single");
    assert.equal(env.snapshot.busy, false);
    assert.match(env.snapshot.error, /Outputs changed, but focus could not be restored.*Timed out/);
});

test("a focus socket failure is reported separately from a successful monitor switch", () => {
    const env = withFocus(setup());
    env.io.focus = () => false;
    env.controller.setMode("single", "DP-1");
    env.drain();
    assert.deepEqual(env.saved, ["single"]);
    assert.match(env.snapshot.error, /Outputs changed, but focus could not be restored.*send/);
    assert.equal(env.snapshot.busy, false);
});

test("a failed activation never sends focus actions", () => {
    const env = withFocus(setup("single", [output("eDP-1"), output("DP-1", false)]));
    env.io.change = (_name, _on, done) => done("Activation failed");
    env.controller.cycle();
    env.drain();
    assert.deepEqual(env.focusRequests, []);
    assert.equal(env.snapshot.error, "Activation failed");
});

test("disposed controllers ignore an outstanding focus query", () => {
    const env = withFocus(setup());
    env.controller.setMode("single", "DP-1");
    let complete;
    env.io.readFocus = done => { complete = done; };
    env.queue.shift()();
    env.controller.dispose();
    complete(null, copy(env.focusState));
    assert.deepEqual(env.focusRequests, []);
    assert.deepEqual(env.saved, []);
});

test("a stale restore retry cannot affect a newer switch", () => {
    const env = withFocus(setup());
    env.controller.setMode("single", "DP-1");
    env.queue.shift()(); // Output confirmation sends focus and schedules verification.
    const oldRetry = env.queue[0];
    env.drain();
    env.controller.cycle();
    const requests = copy(env.focusRequests);
    const commands = copy(env.commands);
    oldRetry();
    assert.deepEqual(env.focusRequests, requests);
    assert.deepEqual(env.commands, commands);
    env.drain();
    assert.deepEqual(env.focusRequests, [[7, 42], [7, 42]]);
    assert.equal(env.snapshot.error, "");
});
