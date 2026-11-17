import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import vm from "node:vm";

const source = await readFile(new URL(
    "../../../dot_config/herdr-app/mods/pbogut-agent-status/main.js",
    import.meta.url,
), "utf8");
const settle = () => new Promise(setImmediate);

async function fixture(checking = false) {
    const context = vm.createContext({});
    const connections = [], timers = [];
    let agents = [];
    function mock(values) {
        return new vm.SyntheticModule(Object.keys(values), function () {
            for (const [key, value] of Object.entries(values)) this.setExport(key, value);
        }, { context });
    }
    const element = { h: () => element };
    const modules = {
        "gpui-kit": mock({ View: class {}, div: () => element }),
        herdr: mock({ checking: () => checking, props: () => checking ? null : { port: 12345 }, agents: () => agents }),
        net: mock({
            connect: async (host, port) => {
                assert.equal(host, "127.0.0.1");
                assert.equal(port, 12345);
                let end;
                const socket = {
                    messages: [],
                    write: async text => { socket.messages.push(JSON.parse(text)); },
                    read: () => new Promise(resolve => { end = resolve; }),
                    close: () => { end?.(null); socket.closed = true; },
                };
                connections.push(socket);
                return socket;
            },
        }),
    };
    const module = new vm.SourceTextModule(source, { context });
    await module.link(name => modules[name]);
    await module.evaluate();
    const cx = { spawn: fn => fn(cx), timer: { after: (ms, fn) => timers.push({ ms, fn }) } };
    const view = new module.namespace.default();
    view.init({}, cx);
    view.render(cx);
    await settle();
    return {
        connections, timers, view, cx,
        async render(next = agents) {
            agents = next;
            view.render(cx);
            await settle();
        },
    };
}

test("sends initial state, then only changes to agent identity, status or focus", async () => {
    const app = await fixture();
    try {
        const socket = app.connections[0];
        assert.deepEqual(socket.messages, [{ version: 1, agents: [] }]);
        await app.render([{ address: "t1", status: "working", focused: true, title: "First" }]);
        await app.render([{ address: "t1", status: "working", focused: true, title: "Second", seq: 99 }]);
        for (let i = 0; i < 100; i++) await app.render();
        assert.equal(socket.messages.length, 2);
        assert.equal(app.timers.length, 0, "connected idle state schedules no refresh timer");
        await app.render([{ address: "t1", status: "done", focused: false }]);
        await app.render([{ address: "t1", status: "idle", focused: true }]);
        assert.deepEqual(socket.messages.slice(-2).map(x => x.agents[0]), [
            { address: "t1", status: "done", focused: false },
            { address: "t1", status: "idle", focused: true },
        ]);
    } finally {
        app.view.close();
    }
});

test("reordering alone sends nothing and reconnect sends the full current snapshot", async () => {
    const app = await fixture();
    try {
        const first = { address: "t1", status: "idle", focused: false };
        const second = { address: "t2", status: "idle", focused: true };
        await app.render([first, second]);
        await app.render([second, first]);
        assert.equal(app.connections[0].messages.length, 2);
        app.connections[0].close();
        await settle();
        assert.equal(app.timers.length, 1);
        app.timers.shift().fn(app.cx);
        await settle();
        assert.deepEqual(app.connections[1].messages, [{ version: 1, agents: [first, second] }]);
    } finally {
        app.view.close();
    }
});

test("coalesces changes during a pending write and closes without reconnecting", async () => {
    const app = await fixture();
    const socket = app.connections[0];
    let finish;
    socket.write = text => {
        socket.messages.push(JSON.parse(text));
        return new Promise(resolve => { finish = resolve; });
    };
    await app.render([{ address: "t1", status: "working", focused: false }]);
    await app.render([{ address: "t1", status: "done", focused: false }]);
    await app.render([{ address: "t1", status: "idle", focused: true }]);
    assert.equal(socket.messages.length, 2);
    finish();
    await settle();
    assert.equal(socket.messages.length, 3);
    assert.equal(socket.messages.at(-1).agents[0].status, "idle");
    app.view.close();
    finish();
    await settle();
    assert.equal(socket.closed, true);
    assert.equal(app.timers.length, 0);
});

test("check mode never opens a connection", async () => {
    const app = await fixture(true);
    await app.render([{ address: "t1", status: "working", focused: false }]);
    assert.equal(app.connections.length, 0);
    assert.equal(app.timers.length, 0);
    app.view.close();
});

test("a late write from a lost connection cannot suppress the reconnect snapshot", async () => {
    const app = await fixture();
    let finish;
    try {
        const old = app.connections[0];
        old.write = () => new Promise(resolve => { finish = resolve; });
        const agent = { address: "t1", status: "idle", focused: true };
        await app.render([agent]);
        old.close();
        await settle();
        app.timers.shift().fn(app.cx);
        await settle();
        assert.equal(app.connections[1].messages.length, 0, "old write is still pending");
        finish();
        await settle();
        assert.deepEqual(app.connections[1].messages, [{ version: 1, agents: [agent] }]);
    } finally {
        app.view.close();
    }
});
