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
