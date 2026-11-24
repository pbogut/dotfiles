"""Exercise session reporting, recreation, and recovery with the real App/core.

The terminal program drives the actual OpenCode TUI plugin with a small session
cache. No model, account, or user OpenCode database is needed.
"""

import json
import os
from pathlib import Path
import select
import shlex
import shutil
import signal
import subprocess
import tempfile
import time


ROOT = Path(__file__).resolve().parents[3]


def main():
    root = Path(tempfile.mkdtemp(prefix="herdr-opencode-", dir="/tmp/opencode"))
    print(f"OpenCode restoration sandbox: {root}", flush=True)
    env = {k: v for k, v in os.environ.items()
           if not k.startswith(("HC_", "HERDR_")) and k not in ("WAYLAND_DISPLAY", "DBUS_SESSION_BUS_ADDRESS", "ZDOTDIR")}
    for key, name in [
        ("HOME", "home"), ("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
        ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "run"),
    ]:
        (root / name).mkdir(mode=0o700)
        env[key] = str(root / name)
    bindir = root / "bin"
    bindir.mkdir()
    shutil.copy2(shutil.which("hc"), bindir / "hc")
    shutil.copyfile(ROOT / "dot_scripts/executable_herdr-app-opencode", bindir / "herdr-app-opencode")
    (bindir / "herdr-app-opencode").chmod(0o700)
    extension = root / "config/opencode/extensions/herdr-subject"
    shutil.copytree(ROOT / "dot_config/opencode/extensions/herdr-subject", extension)
    shutil.copytree(ROOT / "dot_config/herdr-app", root / "app")
    settings_path = root / "app/settings.json"
    settings = json.loads(settings_path.read_text())
    settings.update(core=str(bindir / "hc"), telemetry=False, sounds={"enabled": False})
    settings_path.write_text(json.dumps(settings))
    (root / "app/shared.json").write_text('{"frame.welcomed":"skipped"}')
    (root / "home/.zshrc").write_text(
        f"source {shlex.quote(str(ROOT / 'dot_zshrc.d/herdr-app-opencode.zsh'))}\n")
    env.update(HERDR_APP_HOME=str(root / "app"), HC_SESSION="opencode-test", HERDR_ENV="1",
               HERDR_PANE_ID="stale", HERDR_SOCKET_PATH="/nonexistent",
               HERDR_TELEMETRY="0", SHELL="/usr/bin/zsh", MANGOHUD="0",
               PATH=f"{bindir}:{env['PATH']}", OC_LOG=str(root / "launches.jsonl"),
               OC_PLUGIN=str(extension / "tui.ts"))
    fixture = bindir / "opencode.mjs"
    fixture.write_text("""
#!/usr/bin/env node
import { appendFileSync } from "node:fs";
import { createInterface } from "node:readline";
import { pathToFileURL } from "node:url";
const plugin = (await import(pathToFileURL(process.env.OC_PLUGIN))).default;
let selected = process.argv.includes("--session") ? process.argv[process.argv.indexOf("--session") + 1] : null;
const sessions = new Map([["root-a", {}], ["child-a", { parentID: "root-a" }], ["root-b", {}], ["root-c", {}]]);
const dispose = plugin.setup({
  ui: { router: { current: () => selected ? { type: "session", sessionID: selected } : { type: "home" } } },
  data: { session: { get: id => sessions.get(id), root: id => sessions.get(id)?.parentID ?? id } },
});
appendFileSync(process.env.OC_LOG, JSON.stringify({
  terminal: process.env.HC_TERMINAL_ID, pid: process.pid, args: process.argv.slice(2),
  cwd: process.cwd(), legacy: process.env.HERDR_ENV ?? null, selected,
}) + "\\n");
console.log("OPENCODE-READY", selected);
for await (const line of createInterface({ input: process.stdin })) {
  if (line.startsWith("select ")) selected = line.slice(7);
  if (line === "home") selected = null;
  if (line === "quit") { await dispose?.(); process.exit(0); }
}
""".lstrip())
    fixture.chmod(0o700)
    (bindir / "opencode").symlink_to(fixture)
    project = root / "project's workspace"
    project.mkdir()
    xvfb = subprocess.Popen(["Xvfb", "-displayfd", "1", "-screen", "0", "1280x800x24", "-nolisten", "tcp"],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    env["DISPLAY"] = ":" + xvfb.stdout.readline().strip()

    def call(*args):
        return subprocess.check_output(args, env=env, text=True, stderr=subprocess.STDOUT, timeout=15).strip()

    def app(*args):
        return json.loads(call("herdr-app", *args))

    def rpc(method, params):
        request = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}) + "\n"
        client = subprocess.Popen(["hc", "connect"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, env=env, text=True)
        try:
            client.stdin.write(request)
            client.stdin.flush()
            assert select.select([client.stdout], [], [], 10)[0], f"No core response to {method}"
            response = json.loads(client.stdout.readline())
        finally:
            client.terminate()
            client.communicate(timeout=5)
        assert "error" not in response, response
        return response["result"]

    def wait(check, message, timeout=15):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if check():
                return
            time.sleep(0.05)
        raise AssertionError(message)

    def launches():
        path = root / "launches.jsonl"
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def tabs():
        return next(s["tabs"] for s in app("ls")["spaces"] if s["id"] == space)

    def open_slot(role):
        app("do", f"pbogut-tabs.{role}")
        wait(lambda: any(t["name"] == role for t in tabs()), f"{role} tab opens")
        tab = next(t for t in tabs() if t["name"] == role)
        terminal = tab["terminals"][0]["terminal"]
        wait(lambda: any(r["terminal"] == terminal for r in launches()), f"{role} starts")
        return tab["id"], terminal

    def cached(role):
        saved = rpc("doc.get", {"name": "pbogut-opencode"})["value"] or {}
        return saved.get("slots", {}).get(f"{space}/{role}", {}).get("sessionID")

    def start():
        process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
        call("xdotool", "search", "--sync", "--pid", str(process.pid))
        app("do", "layout.switch", "--name", "pbogut")
        return process

    with (root / "app.log").open("w") as log:
        call("hc", "server", "start")
        process = start()
        try:
            space = app("do", "space.new", "--folder", str(project))["space"]
            first_tab, first = open_slot("oc-1")
            second_tab, second = open_slot("oc-2")
            call("hc", "send", first, "select child-a")
            call("hc", "send", second, "select root-b")
            wait(lambda: cached("oc-1") == "root-a" and cached("oc-2") == "root-b", "Independent root sessions saved")
            assert all(r["legacy"] is None for r in launches()), launches()
            call("hc", "send", first, "select root-c")
            wait(lambda: cached("oc-1") == "root-c", "Selection changes the saved conversation")
            call("hc", "send", first, "home")
            call("hc", "send", first, "quit")
            wait(lambda: all(t["id"] != first_tab for t in tabs()), "Normal exit closes the tab")
            assert cached("oc-1") == "root-c" and cached("oc-2") == "root-b"
            first_tab, first = open_slot("oc-1")
            assert launches()[-1]["args"] == ["--session", "root-c"], launches()

            # Both surviving processes keep their IDs through an App window close.
            before = launches()
            app("do", "window.close")
            process.wait(timeout=5)
            process = start()
            wait(lambda: len(tabs()) == 3, "The saved layout reconnects")
            assert launches() == before
            app("do", "pbogut-tabs.oc-1")
            assert next(t for t in tabs() if t["name"] == "oc-1")["id"] == first_tab

            # Kill only our fixture process. Native keep recovery supplies the
            # new root Zsh; the one-shot hook resumes this terminal's own slot.
            old = rpc("terminal.get", {"terminal": second})
            assert old["keep"]
            os.kill(old["pid"], signal.SIGKILL)
            wait(lambda: len(launches()) == len(before) + 1, "Lost OpenCode resumes", timeout=30)
            resumed = launches()[-1]
            assert resumed["terminal"] == second and resumed["selected"] == "root-b", resumed
            assert resumed["cwd"] == str(project)
            assert next(t for t in tabs() if t["name"] == "oc-2")["id"] == second_tab
            assert app("status")["tab"] == first_tab, "Recovery preserves focus"
            assert cached("oc-1") == "root-c"

            # Stop this isolated core while the App is closed. This exercises
            # durable documents/labels and startup restoration for both slots.
            app("do", "window.close")
            process.wait(timeout=5)
            count = len(launches())
            call("hc", "server", "stop")
            call("hc", "server", "start")
            process = start()
            wait(lambda: len(launches()) == count + 2, "Both slots restore after core shutdown", timeout=30)
            restored = {r["terminal"]: r for r in launches()[-2:]}
            assert restored[first]["selected"] == "root-c"
            assert restored[second]["selected"] == "root-b"
            assert all(r["cwd"] == str(project) for r in restored.values())
            wait(lambda: len(tabs()) == 3, "Restoration preserves the named tabs")
            for terminal in (first, second):
                call("hc", "send", terminal, "quit")
            wait(lambda: len(tabs()) == 1, "Restored programs still close on exit")

            # An already-open, plain `opencode` in a named tab can register
            # through the plugin, without having used the new launch helper.
            old_tab = app("do", "tab.new", "--name", "oc-3", "--argv",
                          json.dumps(["exec", "env", "-u", "HERDR_ENV", "opencode"]))
            third = old_tab["terminal"]
            wait(lambda: any(r["terminal"] == third for r in launches()), "Existing-style launch starts")
            call("hc", "send", third, "select root-a")
            wait(lambda: cached("oc-3") == "root-a", "Plugin adopts the existing named tab")
            call("hc", "send", third, "quit")
            wait(lambda: len(tabs()) == 1, "Adopted tab closes")
            _, third = open_slot("oc-3")
            assert launches()[-1]["selected"] == "root-a"
            call("hc", "send", third, "quit")
            wait(lambda: len(tabs()) == 1, "Adopted session closes after reopening")

            # A custom tab stays a shell after a deliberate quit. A second tab
            # still in OpenCode at shutdown should resume, even after a rename.
            custom = app("do", "tab.new", "--name", "dupa-34")["terminal"]
            call("hc", "send", custom, "env -u HERDR_ENV opencode")
            wait(lambda: any(r["terminal"] == custom for r in launches()), "OpenCode starts in the shell")
            def shows(session, terminal=custom):
                term = rpc("terminal.get", {"terminal": terminal})
                labels = term["labels"]
                pid = (term.get("foreground") or {}).get("pid")
                return labels.get("pbogut.oc.session") == session and labels.get("pbogut.oc.session-pid") == str(pid)

            call("hc", "send", custom, "select child-a")
            wait(lambda: shows("root-a"), "Custom tab reports the child session's root")
            call("hc", "send", custom, "select root-b")
            wait(lambda: shows("root-b"), "Custom tab follows session changes")
            assert rpc("terminal.get", {"terminal": custom})["labels"]["pbogut.oc.resume-dir"]
            assert cached("dupa-34") is None
            call("hc", "send", custom, "quit")
            wait(lambda: not shows("root-b"), "Returning to the shell invalidates the picker identity")
            wait(lambda: not rpc("terminal.get", {"terminal": custom})["labels"].get("pbogut.oc.resume-dir"),
                 "The shell disarms recovery after a normal exit")

            nested = project / "next project's dir"
            nested.mkdir()
            active_tab = app("do", "tab.new", "--name", "scratch")
            active = active_tab["terminal"]
            call("hc", "send", active, f"cd -- {shlex.quote(str(nested))} && env -u HERDR_ENV opencode")
            wait(lambda: any(r["terminal"] == active for r in launches()), "OpenCode starts in the subdirectory")
            call("hc", "send", active, "select root-a")
            wait(lambda: shows("root-a", active), "Custom session selected before reboot")
            app("do", "tab.rename", "--name", "renamed")
            for _ in range(2):
                app("do", "window.close")
                process.wait(timeout=5)
                count = len(launches())
                call("hc", "server", "stop")
                call("hc", "server", "start")
                process = start()
                wait(lambda: len(launches()) > count, "Custom session resumes after core shutdown", timeout=30)
                resumed, = launches()[count:]
                assert (resumed["terminal"], resumed["args"], resumed["cwd"]) == (active, ["--session", "root-a"], str(nested)), resumed
                assert any(t["id"] == active_tab["tab"] and t["name"] == "renamed" for t in tabs()), tabs()
                wait(lambda: shows("root-a", active), "Resumed OpenCode registers its session for the next reboot")
                assert rpc("terminal.get", {"terminal": active})["labels"]["pbogut.oc.resume-dir"] == str(nested)
            call("hc", "send", active, "quit")
            # Prove both restored panes actually accept shell commands.
            for terminal in (active, custom):
                marker = root / f"{terminal}.shell"
                call("hc", "send", terminal, f"touch -- {shlex.quote(str(marker))}")
                wait(marker.exists, "Restored shell accepts commands")
                assert not rpc("terminal.get", {"terminal": terminal})["labels"].get("pbogut.oc.resume-dir")
            assert len(launches()) == count + 1
            assert not app("status")["errors"], app("status")
            print("PASS: selected roots, custom tabs, separate slots, recreation, live reconnect, process loss, core shutdown, existing-tab adoption, and normal exits.", flush=True)
        except Exception as error:
            if isinstance(error, subprocess.CalledProcessError):
                print(error.output, flush=True)
            print("Launches:", launches(), flush=True)
            print((root / "app.log").read_text()[-8000:], flush=True)
            for terminal in rpc("terminal.list", {"all": True})["terminals"]:
                print("Terminal:", terminal, flush=True)
                print(call("hc", "read", terminal["address"], "--lines", "20"), flush=True)
            raise
        finally:
            if process.poll() is None:
                try:
                    app("do", "window.close")
                    process.wait(timeout=5)
                except subprocess.SubprocessError:
                    process.terminate()
                    process.wait(timeout=5)
            subprocess.run(["hc", "server", "stop"], env=env, timeout=5, capture_output=True)
            xvfb.terminate()
            xvfb.wait(timeout=5)


if __name__ == "__main__":
    main()
