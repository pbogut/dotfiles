import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import { runInNewContext } from "node:vm";

const source = await readFile(new URL(
    "../../../dot_config/DankMaterialShell/plugins/HerdrAgents/HerdrAgentsWidget.qml",
    import.meta.url,
), "utf8");
const methods = ["openHerdr", "focusAgent"].map(name =>
    source.match(new RegExp(`    function ${name}\\([^\\n]*\\) \\{[\\s\\S]*?\\n    \\}`))[0]
).join("\n");
const plain = value => JSON.parse(JSON.stringify(value));

function widget(groups = []) {
    const detached = [], commands = [];
    const context = {
        statusData: { groups },
        Quickshell: { execDetached: args => detached.push(plain(args)) },
        Proc: { runCommand: (...args) => commands.push(args) },
    };
    context.root = context;
    runInNewContext(methods, context);
    return { root: context, detached, commands };
}

test("app clicks pass the terminal as one argument and raise the app after selection", () => {
    const { root, detached, commands } = widget();
    root.focusAgent({ source: "herdr-app", terminal_id: "remote/t7" });
    assert.equal(commands.length, 1);
    assert.deepEqual(plain(commands[0][1]), ["herdr-app", "do", "agent.focus", "--terminal", "remote/t7"]);
    assert.equal(detached.length, 0);
    commands[0][2]("", 0);
    assert.deepEqual(detached, [["focus-or-exec", "herdr-app", "herdr-app"]]);
});

test("legacy clicks still target the pane and the legacy terminal window", () => {
    const { root, detached, commands } = widget();
    root.focusAgent({ source: "herdr", pane_id: "w1:p2" });
    assert.equal(commands.length, 0);
    assert.equal(detached.length, 1);
    assert.equal(detached[0].at(-1), "w1:p2");
    assert.match(detached[0][2], /herdr agent focus "\$1"/);
    assert.match(detached[0][2], /Alacritty\.herdr/);
});

test("opening the widget's application uses App when App agents are present", () => {
    const { root, detached } = widget([{ agents: [{ source: "herdr-app" }] }]);
    root.openHerdr();
    root.focusAgent({ source: "herdr-app" });
    root.focusAgent({ source: "herdr" });
    assert.deepEqual(detached.slice(0, 2), [
        ["focus-or-exec", "herdr-app", "herdr-app"],
        ["focus-or-exec", "herdr-app", "herdr-app"],
    ]);
    assert.equal(detached[2][1], "Alacritty.herdr");
});
