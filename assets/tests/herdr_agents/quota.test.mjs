import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import { runInNewContext } from "node:vm";

const plugin = new URL("../../../dot_config/DankMaterialShell/plugins/HerdrAgents/", import.meta.url);
const source = await readFile(new URL("Quota.js", plugin), "utf8");
const daemonSource = await readFile(new URL("HerdrAgentsDaemon.qml", plugin), "utf8");
const { mergeProviders, render } = runInNewContext(`${source}\n({ mergeProviders, render })`);
const plain = (value) => JSON.parse(JSON.stringify(value));
const quotaJson = (providers) => JSON.stringify({ providers });

function provider(fetchedAt, remaining, window = "Weekly") {
    return {
        status: "ok",
        fetchedAt,
        entries: [{ name: `Pro ${window}`, renderType: "percent", window, percentRemaining: remaining, resetAt: 2000 }],
    };
}

function quotaDaemon(providers = {}, env = { HOME: "/mock/home with spaces" }) {
    const calls = { commands: [], saves: [], published: [], reloads: 0, reads: 0, restarts: 0 };
    let fileText = "";
    const root = {
        Quota: { mergeProviders, render },
        quotaProviders: mergeProviders({}, plain(providers)),
        quotaData: {},
        quotaRefreshing: false,
        quotaError: "",
        quotaRefreshSource: "cache",
        shuttingDown: false,
        pluginId: "herdrAgents",
        pluginService: {
            savePluginState: (...args) => calls.saves.push(plain(args)),
            setGlobalVar: (...args) => calls.published.push(plain(args)),
        },
        Quickshell: { env: (name) => env[name] || "" },
        Proc: { runCommand: (...args) => calls.commands.push(args) },
        quotaFile: { reload: () => calls.reloads++, text: () => { calls.reads++; return fileText; } },
        quotaPollTimer: { restart: () => calls.restarts++ },
        console: { warn() {} },
    };
    root.root = root;
    const methods = ["publishQuota", "parseQuota", "finishQuotaRefresh", "refreshQuota"].map((name) => {
        const match = daemonSource.match(new RegExp(`    function ${name}\\([^\\n]*\\) \\{[\\s\\S]*?\\n    \\}`));
        assert.ok(match, `daemon method ${name}`);
        return match[0];
    }).join("\n");
    const paths = ["quotaCacheHome", "quotaCliPath"].map((name) => {
        const match = daemonSource.match(new RegExp(`readonly property string ${name}: ([^\\n]+)`));
        assert.ok(match, `daemon path ${name}`);
        return `var ${name} = ${match[1]};`;
    }).join("\n");
    const handlers = daemonSource.match(/    FileView \{\s+id: quotaFile\b[\s\S]*?onLoaded: \{([\s\S]*?)\n        \}\s+onLoadFailed: ([^\n]+)/);
    assert.ok(handlers, "quota FileView handlers");
    runInNewContext(`${paths}\n${methods}\nfunction onLoaded() {${handlers[1]}}\nfunction onLoadFailed() {${handlers[2]}}`, root);
    return {
        root,
        calls,
        complete: (stdout, exitCode = 0) => calls.commands.at(-1)[2](stdout, exitCode),
        load(text) {
            fileText = text;
            root.onLoaded();
        },
        failLoad: () => root.onLoadFailed(),
    };
}

test("71 old -> 52 new -> 71 old never rolls back, including after restoring persisted JSON", () => {
    let cached = mergeProviders({}, { openai: provider(100, 71) });
    cached = mergeProviders(cached, { openai: provider(200, 52) });
    assert.equal(cached.openai.entries[0].percentRemaining, 52);
    const restored = mergeProviders({}, plain(cached));
    assert.equal(mergeProviders(restored, { openai: provider(100, 71) }), restored);
    assert.equal(mergeProviders(restored, { openai: provider(200, 71) }), restored);
    assert.equal(render(restored).rows[0].percentRemaining, 52);
});

test("merges freshness independently per provider and retains omitted providers", () => {
    const cached = mergeProviders({}, { openai: provider(200, 52), go: provider(100, 96) });
    const next = mergeProviders(cached, { openai: provider(100, 71), go: provider(300, 85) });
    assert.equal(next.openai, cached.openai);
    assert.equal(next.go.fetchedAt, 300);
    assert.equal(mergeProviders(next, { go: provider(200, 96) }), next);
    assert.equal(cached.go.fetchedAt, 100, "merging must not mutate persisted state");
});

test("newer fetches can increase quota and replace a provider's entire set of windows", () => {
    const old = provider(100, 52);
    old.entries.push(...provider(100, 30, "5h").entries);
    const cached = mergeProviders({}, { openai: old });
    const reset = provider(200, 100);
    reset.entries[0].resetAt = 4000;
    const next = mergeProviders(cached, { openai: reset });
    assert.equal(next.openai.entries.length, 1);
    assert.equal(next.openai.entries[0].percentRemaining, 100);
    assert.equal(next.openai.entries[0].resetAt, 4000);
});

test("a newer fetch is retained even when the percentage has not changed", () => {
    const cached = mergeProviders({}, { openai: provider(100, 52) });
    const next = mergeProviders(cached, { openai: provider(200, 52) });
    assert.equal(next.openai.fetchedAt, 200);
    assert.equal(mergeProviders(next, { openai: provider(150, 71) }), next);
});

test("unavailable, malformed, empty and undated snapshots cannot erase good data", () => {
    const cached = mergeProviders({}, { openai: provider(100, 52) });
    for (const incoming of [null, [], "invalid", {}, { openai: null }])
        assert.equal(mergeProviders(cached, incoming), cached);
    for (const patch of [
        { status: "unavailable" }, { status: "error" }, { entries: [] }, { entries: null },
        { entries: [null, { renderType: "percent", percentRemaining: null }] },
        { fetchedAt: undefined }, { fetchedAt: null }, { fetchedAt: "300" },
        { fetchedAt: -1 }, { fetchedAt: Infinity }, { fetchedAt: NaN }, { fetchedAt: Date.now() / 1000 + 3600 },
    ]) {
        assert.equal(mergeProviders(cached, { openai: { ...provider(300, 71), ...patch } }), cached);
    }
});

test("partial snapshots keep only sanitized percentage entries", () => {
    const input = provider(100, 120);
    input.status = "partial";
    input.secret = "must not be persisted";
    input.entries.push(null, { renderType: "text" }, ...provider(100, -10, "5h").entries);
    const cached = mergeProviders({}, { openai: input });
    assert.equal(cached.openai.status, "partial");
    assert.equal(cached.openai.secret, undefined);
    assert.deepEqual(plain(cached.openai.entries.map((entry) => entry.percentRemaining)), [100, 0]);
});

test("render preserves per-provider fetch ages and the existing provider/window sort", () => {
    const go = provider(100, 96);
    go.entries.unshift(...provider(100, 85, "Monthly").entries);
    go.entries.push(...provider(100, 100, "5h").entries);
    const cached = mergeProviders({}, { openai: provider(200, 52), go });
    const output = plain(render(cached));
    assert.equal(output.updatedAt, 100);
    assert.deepEqual(output.rows.map(({ providerId, window, fetchedAt }) => [providerId, window, fetchedAt]), [
        ["go", "5h", 100], ["go", "Weekly", 100], ["go", "Monthly", 100], ["openai", "Weekly", 200],
    ]);
    assert.deepEqual(plain(render({})), { updatedAt: 0, rows: [] });
});

test("daemon ignores fresh export timestamps and persists only newer provider data", async () => {
    const daemon = await readFile(new URL("HerdrAgentsDaemon.qml", plugin), "utf8");
    const parser = daemon.match(/    function parseQuota\(text\) \{[\s\S]*?\n    \}/)[0];
    const saves = [];
    const published = [];
    const context = {
        Quota: { mergeProviders, render },
        quotaProviders: mergeProviders({}, { openai: provider(200, 52) }),
        pluginId: "herdrAgents",
        pluginService: { savePluginState: (...args) => saves.push(plain(args)) },
        publishQuota: (value) => published.push(plain(value)),
        console: { warn() {} },
    };
    const parseQuota = runInNewContext(`${parser}\nparseQuota`, context);
    for (const text of ["", "{", "null", "{}", JSON.stringify({ providers: { openai: { status: "unavailable" } } })])
        assert.equal(parseQuota(text), null);
    const old = parseQuota(JSON.stringify({ exportedAt: 999999, providers: { openai: provider(100, 71) } }));
    assert.equal(old.openai.fetchedAt, 100, "unchanged data is still a usable response");
    assert.equal(saves.length, 0);
    assert.equal(published.length, 0);
    assert.equal(context.quotaProviders.openai.entries[0].percentRemaining, 52);
    parseQuota(JSON.stringify({ exportedAt: 999999, providers: { openai: provider(300, 50) } }));
    assert.equal(saves.length, 1);
    assert.deepEqual(saves[0], ["herdrAgents", "quotaProviders", plain(context.quotaProviders)]);
    assert.equal(published[0].updatedAt, 300);
});

test("daemon runs the exact CLI command with a 30-second timeout and a fifteen-minute poll", () => {
    assert.match(daemonSource, /Timer \{\s+id: quotaPollTimer\s+interval: 15 \* 60 \* 1000\s+repeat: true\s+running: true\s+onTriggered: root\.refreshQuota\(\)/);
    for (const cacheHome of [undefined, "/mock/cache with spaces"]) {
        const env = { HOME: "/mock/home with spaces", XDG_CACHE_HOME: cacheHome };
        const { root, calls, complete } = quotaDaemon({}, env);
        assert.equal(root.refreshQuota(), true);
        assert.equal(root.quotaData.refreshing, true);
        assert.equal(calls.restarts, 1);
        assert.equal(calls.commands.length, 1);
        const [target, args, callback, ...options] = calls.commands[0];
        assert.equal(target, null);
        assert.deepEqual(plain(args), [
            "env", "--chdir", env.HOME, "node",
            `${cacheHome || env.HOME + "/.cache"}/opencode/packages/@slkiser/opencode-quota@latest/node_modules/@slkiser/opencode-quota/dist/bin/opencode-quota.js`,
            "show", "--json",
        ]);
        assert.equal(typeof callback, "function");
        assert.deepEqual(options, [0, 30000]);
        complete(quotaJson({ openai: provider(200, 52) }));
        assert.equal(calls.reloads, 0);
        assert.equal(root.quotaRefreshing, false);
        assert.deepEqual(plain(root.quotaData), {
            ...plain(render(root.quotaProviders)), refreshing: false, error: "", refreshSource: "cli",
        });
        assert.deepEqual(calls.saves, [["herdrAgents", "quotaProviders", plain(root.quotaProviders)]]);
        assert.deepEqual(calls.published.at(-1), ["herdrAgents", "quota", plain(root.quotaData)]);
    }
});

test("unchanged and older usable CLI data finish without falling back or persisting again", () => {
    for (const [fetchedAt, openaiRemaining, goRemaining] of [[200, 52, 85], [200, 71, 96], [100, 71, 96]]) {
        const { root, calls, complete } = quotaDaemon({ openai: provider(200, 52), go: provider(200, 85) });
        const retained = root.quotaProviders;
        root.refreshQuota();
        complete(quotaJson({ openai: provider(fetchedAt, openaiRemaining), go: provider(fetchedAt, goRemaining) }));
        assert.equal(root.quotaProviders, retained);
        assert.equal(calls.saves.length, 0);
        assert.equal(calls.reloads, 0);
        assert.equal(root.quotaData.refreshing, false);
        assert.equal(root.quotaData.error, "");
        assert.equal(root.quotaData.refreshSource, "cli");
        assert.deepEqual(plain(root.quotaData.rows), plain(render(retained).rows));
    }
});

for (const [name, exitCode, stdout, error] of [
    ["exit 1", 1, quotaJson({ openai: provider(300, 10) }), "Quota command failed"],
    ["exit 127", 127, "", "Quota command failed"],
    ["timeout exit 124", 124, quotaJson({ openai: provider(300, 10) }), "Quota command timed out"],
    // Node reports a missing entry script on stderr, leaving stdout empty.
    ["missing CLI script", 1, "", "Quota command failed"],
]) {
    test(`daemon falls back after ${name} and ignores failed stdout`, () => {
        const { root, calls, complete, load } = quotaDaemon({ openai: provider(200, 52) });
        const retained = root.quotaProviders;
        root.refreshQuota();
        complete(stdout, exitCode);
        assert.equal(calls.reloads, 1);
        assert.equal(calls.reads, 1, "lazy FileView needs an explicit text demand to start loading");
        assert.equal(root.quotaRefreshing, true);
        assert.equal(root.quotaError, error);
        assert.equal(root.quotaProviders, retained);
        assert.equal(calls.saves.length, 0);
        load(quotaJson({ openai: provider(250, 40) }));
        assert.equal(root.quotaProviders.openai.fetchedAt, 250);
        assert.equal(calls.saves.length, 1);
        assert.equal(root.quotaData.refreshing, false);
        assert.equal(root.quotaData.error, "");
        assert.equal(root.quotaData.refreshSource, "export");
    });
}

for (const [name, stdout] of [
    ["empty", ""], ["whitespace", " \n\t"], ["malformed", "{"], ["null", "null"],
    ["missing providers", "{}"], ["empty providers", quotaJson({})],
    ["unavailable", quotaJson({ openai: { ...provider(300, 10), status: "unavailable" } })],
]) {
    test(`daemon falls back for ${name} CLI JSON without erasing retained quota`, () => {
        const { root, calls, complete, load } = quotaDaemon({ openai: provider(200, 52) });
        const retained = root.quotaProviders;
        root.refreshQuota();
        complete(stdout);
        assert.equal(calls.reloads, 1);
        assert.equal(root.quotaRefreshing, true);
        assert.equal(root.quotaError, "CLI returned incomplete quota");
        assert.equal(root.quotaProviders, retained);
        load(quotaJson({ openai: provider(100, 71) }));
        assert.equal(root.quotaProviders, retained, "older usable export must not roll back quota");
        assert.equal(calls.saves.length, 0);
        assert.equal(root.quotaData.refreshing, false);
        assert.equal(root.quotaData.error, "");
        assert.equal(root.quotaData.refreshSource, "export");
    });
}

test("CLI missing a retained provider falls back and persists the freshest snapshot per provider", () => {
    const { root, calls, complete, load } = quotaDaemon({ openai: provider(200, 52), go: provider(100, 96) });
    root.refreshQuota();
    complete(quotaJson({ openai: provider(300, 40) }));
    assert.equal(calls.reloads, 1);
    assert.equal(root.quotaRefreshing, true);
    assert.equal(root.quotaError, "CLI returned incomplete quota");
    assert.equal(root.quotaRefreshSource, "cli+export");
    assert.deepEqual(plain(root.quotaProviders), { openai: provider(300, 40), go: provider(100, 96) });
    load(quotaJson({ openai: provider(250, 71), go: provider(400, 85) }));
    const expected = { openai: provider(300, 40), go: provider(400, 85) };
    assert.deepEqual(plain(root.quotaProviders), expected);
    assert.deepEqual(calls.saves, [
        ["herdrAgents", "quotaProviders", { openai: provider(300, 40), go: provider(100, 96) }],
        ["herdrAgents", "quotaProviders", expected],
    ]);
    assert.deepEqual(plain(root.quotaData), {
        ...plain(render(expected)), refreshing: false, error: "", refreshSource: "cli+export",
    });
});

test("failed or unusable export after CLI failure retains cache and publishes both errors", () => {
    for (const exportText of [undefined, "", "{", quotaJson({ openai: { status: "unavailable" } })]) {
        const { root, calls, complete, load, failLoad } = quotaDaemon({ openai: provider(200, 52) });
        const retained = root.quotaProviders;
        root.refreshQuota();
        complete("", 124);
        if (exportText === undefined)
            failLoad();
        else
            load(exportText);
        const error = "Quota command timed out; " + (exportText === undefined ? "export unavailable" : "export has no usable quota");
        assert.equal(root.quotaProviders, retained);
        assert.equal(calls.saves.length, 0);
        assert.equal(calls.reloads, 1);
        assert.equal(root.quotaRefreshing, false);
        assert.equal(root.quotaError, error);
        assert.deepEqual(plain(root.quotaData), {
            ...plain(render(retained)), refreshing: false, error, refreshSource: "export",
        });
        assert.deepEqual(calls.published.at(-1), ["herdrAgents", "quota", plain(root.quotaData)]);
    }
});

test("busy guard prevents overlapping commands during both CLI and export refresh", () => {
    const { root, calls, complete, failLoad } = quotaDaemon();
    assert.equal(root.refreshQuota(), true);
    assert.equal(root.refreshQuota(), false);
    complete("", 1);
    assert.equal(root.refreshQuota(), false);
    assert.equal(calls.commands.length, 1);
    assert.equal(calls.restarts, 1);
    assert.equal(calls.reloads, 1);
    assert.equal(calls.published.length, 1);
    failLoad();
    assert.equal(root.refreshQuota(), true);
    assert.equal(root.quotaData.error, "", "a new attempt clears the previous error immediately");
    assert.equal(root.quotaData.refreshing, true);
    assert.equal(calls.commands.length, 2);
    assert.equal(calls.restarts, 2);
    complete(quotaJson({ openai: provider(300, 40) }));
    assert.equal(calls.reloads, 1, "recovered CLI must not reload the export");
    assert.equal(root.quotaData.error, "");
    assert.equal(root.quotaData.refreshing, false);
    assert.equal(root.quotaData.refreshSource, "cli");
    assert.equal(root.quotaProviders.openai.fetchedAt, 300);
    assert.equal(calls.saves.length, 1);
});

test("CLI callbacks after shutdown neither publish, persist nor start fallback", () => {
    for (const exitCode of [0, 1, 124]) {
        const { root, calls, complete } = quotaDaemon({ openai: provider(200, 52) });
        root.refreshQuota();
        const retained = root.quotaProviders;
        const published = plain(root.quotaData);
        root.shuttingDown = true;
        complete(quotaJson({ openai: provider(300, 40) }), exitCode);
        assert.equal(root.quotaProviders, retained);
        assert.deepEqual(plain(root.quotaData), published);
        assert.equal(root.quotaRefreshing, true, "ignored callbacks must not finish a refresh");
        assert.equal(calls.published.length, 1);
        assert.equal(calls.saves.length, 0);
        assert.equal(calls.reloads, 0);
        root.quotaRefreshing = false;
        assert.equal(root.refreshQuota(), false, "shutdown blocks refresh even when not busy");
        assert.equal(calls.commands.length, 1);
        assert.equal(calls.restarts, 1);
    }
});

test("duplicate timeout and late exit callbacks are ignored, including during the next refresh", () => {
    const { root, calls, complete, failLoad } = quotaDaemon({ openai: provider(200, 52) });
    root.refreshQuota();
    const oldCallback = calls.commands[0][2];
    oldCallback("", 124);
    oldCallback("", 15);
    assert.equal(calls.reloads, 1);
    assert.equal(root.quotaError, "Quota command timed out");
    failLoad();
    assert.equal(root.quotaData.error, "Quota command timed out; export unavailable");
    root.refreshQuota();
    oldCallback(quotaJson({ openai: provider(900, 71) }), 0);
    assert.equal(root.quotaRefreshing, true);
    assert.equal(calls.saves.length, 0);
    complete(quotaJson({ openai: provider(300, 50) }));
    assert.equal(root.quotaRefreshing, false);
    assert.equal(root.quotaProviders.openai.fetchedAt, 300);
});

test("widget refresh button calls quota IPC without closing the popout", async () => {
    const widget = await readFile(new URL("HerdrAgentsWidget.qml", plugin), "utf8");
    const refresh = widget.match(/    function refreshQuota\(\) \{[\s\S]*?\n    \}/)[0];
    const commands = [];
    runInNewContext(`${refresh}\nrefreshQuota()`, { Quickshell: { execDetached: (args) => commands.push(plain(args)) } });
    assert.deepEqual(commands, [["dms", "ipc", "call", "herdr-agents", "refreshQuota"]]);
    assert.match(widget, /enabled: !root\.quotaRefreshing\s+onClicked: root\.refreshQuota\(\)/);
    assert.doesNotMatch(refresh, /closePopout/);
});

test("widget ages and reset countdowns follow the clock, not the latest export", async () => {
    const widget = await readFile(new URL("HerdrAgentsWidget.qml", plugin), "utf8");
    const ageFunction = widget.match(/    function quotaAgeText\(fetchedAt\) \{[\s\S]*?\n    \}/)[0];
    const resetFunction = widget.match(/    function quotaResetText\(row\) \{[\s\S]*?\n    \}/)[0];
    const clock = { quotaNow: 1788726365000 };
    const { quotaAgeText, quotaResetText } = runInNewContext(`${ageFunction}\n${resetFunction}\n({ quotaAgeText, quotaResetText })`, clock);
    assert.equal(quotaAgeText(1788637016), "24h ago");
    assert.equal(quotaAgeText(1788726365), "just now");
    assert.equal(quotaAgeText(0), "");
    assert.equal(quotaResetText({ resetAt: 1788726425 }), "resets in 1m");
    clock.quotaNow += 3600000;
    assert.equal(quotaAgeText(1788637016), "25h ago");
    assert.equal(quotaResetText({ resetAt: 1788726425 }), "reset passed");
    // First data can arrive long after widget creation; don't wait for a timer tick.
    assert.match(widget, /running: root\.quotaRows\.length > 0\s+triggeredOnStart: true/);
});
