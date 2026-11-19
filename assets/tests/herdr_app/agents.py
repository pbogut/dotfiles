"""Check the folder/priority sidebar with real status-reporting terminals in an isolated app."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
from urllib.parse import quote

from PIL import Image

SOURCE = Path(__file__).resolve().parents[3] / "dot_config/herdr-app"


def main():
    root = Path(tempfile.mkdtemp(prefix="herdr-agents-", dir="/tmp/opencode"))
    print(f"Agents sandbox: {root}", flush=True)
    env = {key: value for key, value in os.environ.items()
           if not key.startswith(("HC_", "HERDR_", "GIT_"))
           and key not in ("WAYLAND_DISPLAY", "DBUS_SESSION_BUS_ADDRESS", "ZDOTDIR")}
    for key, name in [("HOME", "home"), ("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                      ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "run")]:
        (root / name).mkdir(mode=0o700)
        env[key] = str(root / name)
    env.update(HERDR_APP_HOME=str(root / "app"), HC_SESSION="agents-test",
               HERDR_TELEMETRY="0", SHELL="/bin/sh", MANGOHUD="0",
               GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1",
               GIT_AUTHOR_NAME="Test", GIT_AUTHOR_EMAIL="test@example.com",
               GIT_COMMITTER_NAME="Test", GIT_COMMITTER_EMAIL="test@example.com")
    for mod in ["pbogut-spaces", "pbogut-agents", "pbogut-keys"]:
        shutil.copytree(SOURCE / "mods" / mod, root / "app/mods" / mod)
    shutil.copyfile(SOURCE / "keys.json", root / "app/keys.json")
    (root / "app/layouts").mkdir()
    layout = json.loads((SOURCE / "layouts/pbogut.json").read_text())
    sidebar = layout["children"][0]
    sidebar["children"] = [sidebar["children"][1]]
    sidebar["children"][0]["children"][0]["size"] = {"px": 180}
    work = layout["children"][1]
    work["children"] = [{"id": "main", "type": "block", "content": {"tab": "active"}},
                        next(node for node in work["children"] if node["id"] == "prefix-anchor")]
    layout["children"].append({"id": "test-projects", "type": "block", "size": {"px": 0}, "min": 0,
                               "content": {"mod": "test-projects"}})
    (root / "app/layouts/pbogut.json").write_text(json.dumps(layout))
    (root / "app/settings.json").write_text(json.dumps({
        "core": shutil.which("hc"), "telemetry": False, "sounds": {"enabled": False},
    }))
    (root / "app/shared.json").write_text(json.dumps({
        "frame.welcomed": "skipped", "agents.sort": "folder-priority",
    }))
    for name in ["work", "personal"]:
        (root / name).mkdir()
    (root / "work/herdr-project.json").write_text(json.dumps({"name": "Pharmacy"}))
    # Mark the fixture as a project, as the project picker would.
    controller = root / "app/mods/test-projects"
    controller.mkdir()
    (controller / "main.js").write_text("""
import { View, div } from "gpui-kit";
import { spaces, shared, setShared } from "herdr";
export default class Projects extends View {
  render() {
    const marked = Object.fromEntries(spaces().filter(s => s.folder === """ + json.dumps(str(root / "work")) + """)
      .map(s => [s.id, true]));
    if (JSON.stringify(shared("pbogut.projects.spaces")) !== JSON.stringify(marked))
      setShared("pbogut.projects.spaces", marked);
    return div().h(0);
  }
}
""")
    (root / "app/folders.json").write_text(json.dumps({
        "folders": ["work", "personal"], "fallback": "other",
        "rules": [{"path": str(root / name), "folder": name} for name in ["work", "personal"]],
    }))
    # Observe the real render's grouping only in the disposable copy.
    main_js = root / "app/mods/pbogut-agents/main.js"
    main_js.write_text(main_js.read_text().replace("    const drawGroup =", """
    const testSnapshot = JSON.stringify(groups.map(g => ({
      label: g.label, members: g.members.map(a => a.address),
      labels: g.members.map(a => ({ address: a.address, name: nameOf(a), branch: branchOf(a) })),
      sections: g.sections?.map(s => ({ label: s.label, members: s.members.map(a => a.address) })),
    })));
    if (testSnapshot !== this.testSnapshot) {
      console.log("AGENT_GROUPS " + testSnapshot);
      this.testSnapshot = testSnapshot;
    }
    const drawGroup ="""))
    picker_js = root / "app/mods/pbogut-agents/picker.js"
    picker_js.write_text(picker_js.read_text().replace("    const height =", """
    const snapshot = JSON.stringify({ query: this.query, selected: this.selected, rows });
    if (snapshot !== this.testSnapshot) {
      console.log("AGENT_PICKER " + snapshot);
      this.testSnapshot = snapshot;
    }
    const height ="""))

    def call(*args):
        return subprocess.check_output(args, env=env, text=True, stderr=subprocess.STDOUT, timeout=15).strip()

    def app(*args):
        return json.loads(call("herdr-app", *args))

    def wait(check, message):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if check():
                return
            time.sleep(0.05)
        raise AssertionError(message)

    def groups():
        records = [line.split("AGENT_GROUPS ", 1)[1] for line in (root / "app.log").read_text().splitlines()
                   if "AGENT_GROUPS " in line]
        return json.JSONDecoder().raw_decode(records[-1])[0] if records else []

    def sections():
        return {g["label"]: {s["label"]: s["members"] for s in g.get("sections", [])}
                for g in groups() if "sections" in g}

    def labels():
        return {a["address"]: a for g in groups() for a in g["labels"]}

    def picker_state():
        records = [line.split("AGENT_PICKER ", 1)[1] for line in (root / "app.log").read_text().splitlines()
                   if "AGENT_PICKER " in line]
        return json.JSONDecoder().raw_decode(records[-1])[0] if records else {}

    def key(*keys):
        call("xdotool", "key", "--clearmodifiers", "--delay", "80", *keys)

    def open_picker():
        call("xdotool", "keydown", "Alt_L", "key", "i", "key", "i", "keyup", "Alt_L")
        wait(lambda: "pbogut-agents" in app("status")["overlays"], "Double Alt+I opens the agent picker")

    call("git", "-C", str(root / "work"), "init", "-b", "2026-11-18-feature")
    call("git", "-C", str(root / "work"), "commit", "--allow-empty", "-m", "Fixture")
    writers = []

    def agent(name, status):
        fifo = root / name
        os.mkfifo(fifo)
        code = (
            "import sys\n"
            "with open(sys.argv[1]) as stream:\n"
            " for state in stream:\n"
            "  print(chr(27)+']7501;state='+state.strip()+':app=agents-test'+chr(27)+chr(92),end='',flush=True)\n"
        )
        created = app("do", "tab.new", "--name", name, "--argv",
                      json.dumps(["exec", "python3", "-u", "-c", code, str(fifo)]))
        descriptor = None

        def connect():
            nonlocal descriptor
            try:
                descriptor = os.open(fifo, os.O_WRONLY | os.O_NONBLOCK)
                return True
            except OSError:
                return False

        wait(connect, "Agent terminal opens its status stream")
        writer = os.fdopen(descriptor, "w", buffering=1)
        writers.append(writer)
        writer.write(status + "\n")
        wait(lambda: any(created["terminal"] in g["members"] for g in groups()), "Agent status reaches the sidebar")
        return created["terminal"], writer

    xvfb = subprocess.Popen(["Xvfb", "-displayfd", "1", "-screen", "0", "1100x850x24", "-nolisten", "tcp"],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    env["DISPLAY"] = ":" + xvfb.stdout.readline().strip()
    with (root / "app.log").open("w") as log:
        process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
        try:
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            call("xdotool", "windowfocus", window)
            app("do", "layout.switch", "--name", "pbogut")
            app("do", "space.new", "--name", "API", "--folder", str(root / "work"))
            idle, _ = agent("idle-agent", "idle")
            blocked, writer = agent("blocked-agent", "blocked")
            app("do", "space.new", "--name", "Notes", "--folder", str(root / "personal"))
            busy, _ = agent("busy-agent", "working")
            pinned, _ = agent("pinned-agent", "idle")
            app("do", "terminal.pin", json.dumps({"terminal": pinned, "pinned": True}))
            wait(lambda: sections() == {"work": {"Needs you": [blocked], "Idle": [idle]},
                                       "personal": {"Working": [busy]}}, "Folders contain their priority sections")
            assert [g["label"] for g in groups()] == ["Pinned", "work", "personal"]
            assert groups()[0]["members"] == [pinned]
            wait(lambda: labels().get(blocked) == {
                "address": blocked, "name": "Pharmacy", "branch": "2026-11-18-feature",
            }, "Agents inherit the actual project name and branch resolved by Spaces")
            assert labels()[busy]["name"] == "Notes" and labels()[busy]["branch"] == ""
            call("herdr-app", "shot", str(root / "folder-priority.png"))
            (root / "work/herdr-project.json").write_text(json.dumps({"name": "PMS"}))
            app("do", "pbogut-spaces.reload@" + quote(json.dumps({"folder": str(root / "work")}), safe=""))
            wait(lambda: labels().get(blocked, {}).get("name") == "PMS", "Project config reload updates agent labels")
            call("herdr-app", "shot", str(root / "project-labels.png"))
            key("alt+i")
            wait(lambda: "pbogut-keys" in app("status")["overlays"], "Agent hints take focus")
            call("herdr-app", "shot", str(root / "agent-hints.png"))
            with Image.open(root / "agent-hints.png") as image:
                assert len(image.crop((19, 259, 31, 271)).getcolors()) > 1, "First agent hint F is blank"
            key("j")
            wait(lambda: app("status")["agent"] == blocked, "Second hint focuses the second sidebar agent")
            app("do", "agent.focus", "--terminal", pinned)
            for address in [blocked, idle, busy]:
                app("do", "agent.next")
                wait(lambda: app("status")["agent"] == address, "Navigation follows folder/priority order")
            writer.write("working\n")
            wait(lambda: sections().get("work", {}).get("Working") == [blocked], "A status change moves its section")
            open_picker()
            wait(lambda: picker_state().get("selected") == busy, "The picker starts on the current agent")
            assert [row["address"] for row in picker_state()["rows"]] == [pinned, blocked, idle, busy]
            work_row = next(row for row in picker_state()["rows"] if row["address"] == blocked)
            assert work_row["name"] == "PMS" and work_row["branch"] == "2026-11-18-feature"
            assert work_row["path"] == str(root / "work") and work_row["folder"] == "work"
            assert work_row["machine"] is None and work_row["status"] == "working"
            call("herdr-app", "shot", str(root / "agent-picker.png"))
            writer.write("blocked\n")
            wait(lambda: any(row["address"] == blocked and row["status"] == "blocked"
                             for row in picker_state().get("rows", [])), "The open picker updates agent statuses")
            assert picker_state()["selected"] == busy
            key("ctrl+j", "Return")
            wait(lambda: not app("status")["overlays"] and app("status")["agent"] == pinned,
                 "Ctrl+J wraps to the first agent and Enter focuses it")
            open_picker()
            call("xdotool", "type", "--clearmodifiers", "PMS work")
            wait(lambda: picker_state().get("query") == "PMS work", "Search accepts project and folder words")
            assert [row["address"] for row in picker_state()["rows"]] == [blocked, idle]
            key("ctrl+k", "Return")
            wait(lambda: not app("status")["overlays"] and app("status")["agent"] == idle,
                 "Ctrl+K wraps through the filtered agents")
            open_picker()
            call("xdotool", "type", "--clearmodifiers", "no-agent-matches")
            wait(lambda: picker_state().get("rows") == [], "No matching agents leaves an empty picker")
            key("ctrl+j", "Return")
            assert "pbogut-agents" in app("status")["overlays"]
            key("Escape")
            wait(lambda: not app("status")["overlays"], "Escape closes the picker")
            assert not app("status")["errors"], app("status")
            print("PASS: sidebar order, project labels, and Alt+I picker search, metadata, live status, and agent focus.", flush=True)
        except Exception:
            print((root / "app.log").read_text()[-6000:], flush=True)
            print("Status:", app("status"), flush=True)
            raise
        finally:
            for writer in writers:
                writer.close()
            try:
                app("do", "window.close")
            except Exception:
                process.terminate()
            process.wait(timeout=5)
            subprocess.run(["hc", "kill-server"], env=env, capture_output=True, timeout=5)
            xvfb.terminate()
            xvfb.wait(timeout=5)


if __name__ == "__main__":
    main()
