"""Check folder ordering and keyboard navigation in an isolated Herdr window."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

from PIL import Image, ImageColor

ROOT = Path(__file__).resolve().parents[3]


def main():
    root = Path(tempfile.mkdtemp(prefix="herdr-space-folders-", dir="/tmp/opencode"))
    print(f"Folder sidebar sandbox: {root}", flush=True)
    env = {key: value for key, value in os.environ.items()
           if not key.startswith(("HC_", "HERDR_", "GIT_"))
           and key not in ("WAYLAND_DISPLAY", "DBUS_SESSION_BUS_ADDRESS", "ZDOTDIR")}
    for key, name in [("HOME", "home"), ("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                      ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "run")]:
        (root / name).mkdir(mode=0o700)
        env[key] = str(root / name)
    env.update(HERDR_APP_HOME=str(root / "app"), HC_SESSION="space-folders-test",
               HERDR_TELEMETRY="0", SHELL="/bin/sh", MANGOHUD="0",
               GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1",
               GIT_AUTHOR_NAME="Test", GIT_AUTHOR_EMAIL="test@example.com",
               GIT_COMMITTER_NAME="Test", GIT_COMMITTER_EMAIL="test@example.com")
    shutil.copytree(ROOT / "dot_config/herdr-app", root / "app")
    shutil.copyfile(Path(__file__).with_name("fixtures") / "folders.json", root / "app/folders.json")
    settings = json.loads((root / "app/settings.json").read_text())
    settings.update(core=shutil.which("hc"), telemetry=False, sounds={"enabled": False})
    (root / "app/settings.json").write_text(json.dumps(settings))
    (root / "app/shared.json").write_text(json.dumps({"frame.welcomed": "skipped"}))

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

    def key(*keys):
        call("xdotool", "key", "--clearmodifiers", "--delay", "80", *keys)

    def selected_top(name):
        path = root / f"{name}.png"
        call("herdr-app", "shot", str(path))
        selected = ImageColor.getrgb("#283457")
        with Image.open(path) as image:
            image = image.convert("RGB")
            return next((y for y in range(80, 350) if image.getpixel((10, y)) == selected), None)

    notes = root / "notes"
    personal = root / "repos/github.com/example-personal/dotfiles"
    project = root / "repos/gitlab.com/example-work/pms"
    for folder in (notes, personal, project):
        folder.mkdir(parents=True)
    call("git", "-C", str(project), "init", "--bare", ".bare")
    (project / ".git").write_text("gitdir: ./.bare\n")
    main_tree, outside = project / "main", root / "unrelated/worktree"
    outside.parent.mkdir()
    call("git", "-C", str(project), "worktree", "add", "--orphan", "-b", "main", str(main_tree))
    call("git", "-C", str(main_tree), "-c", "commit.gpgsign=false", "commit", "--allow-empty", "-m", "fixture")
    call("git", "-C", str(project), "worktree", "add", "-b", "2026-11-18-feature", str(outside), "main")
    (project / "herdr-project.json").write_text('{"name":"Pharmacy"}')
    expected = [str(main_tree), str(outside), str(personal), str(notes)]

    xvfb = subprocess.Popen(["Xvfb", "-displayfd", "1", "-screen", "0", "1280x800x24", "-nolisten", "tcp"],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    env["DISPLAY"] = ":" + xvfb.stdout.readline().strip()
    with (root / "app.log").open("w") as log:
        process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
        try:
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            call("xdotool", "windowfocus", window)
            app("do", "layout.switch", "--name", "pbogut")
            opened = {}
            for name, folder in [("Notes", notes), ("Dotfiles", personal), ("Main name", main_tree), ("Feature name", outside)]:
                opened[str(folder)] = app("do", "space.new", "--name", name, "--folder", str(folder))["space"]
            wait(lambda: [s["folder"] for s in app("ls")["spaces"]] == expected, "Core space order matches work, personal, other")
            for number, folder in enumerate(expected, 1):
                key(f"alt+{number}")
                wait(lambda: app("status")["space"] == opened[folder], f"Alt+{number} selects the grouped space")
            key("ctrl+shift+Page_Up")
            wait(lambda: app("status")["space"] == opened[str(personal)], "Previous space follows folder order")
            before = selected_top("folders")
            assert before is not None
            call("xdotool", "mousemove", "100", "93", "click", "1")
            wait(lambda: selected_top("folded") == before - 60, "Folding work hides its two rows")
            key("alt+1")
            wait(lambda: app("status")["space"] == opened[str(main_tree)], "Numbered shortcuts include folded spaces")
            key("ctrl+shift+Page_Down")
            wait(lambda: app("status")["space"] == opened[str(outside)], "Next selects the other worktree")
            key("ctrl+shift+Page_Down")
            wait(lambda: app("status")["space"] == opened[str(personal)], "Next crosses into personal")
            wait(lambda: selected_top("revealed") == before, "Selecting a folded space expands its folder")

            key("alt+4")
            wait(lambda: app("status")["space"] == opened[str(notes)], "Select other before showing empty folders")
            before = selected_top("empty-hidden")
            config = json.loads((root / "app/folders.json").read_text())
            config["folders"].append("research")
            (root / "app/folders.json").write_text(json.dumps(config))
            call("xdotool", "mousemove", "219", "61", "click", "1")
            wait(lambda: selected_top("empty-shown") == before + 28, "Edited config reloads and the toggle reveals its empty folder")

            app("do", "window.close")
            process.wait(timeout=5)
            process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            call("xdotool", "windowfocus", window)
            app("do", "layout.switch", "--name", "pbogut")
            app("do", "space.select", "--id", opened[str(notes)])
            wait(lambda: selected_top("restarted") == before + 28, "The empty-folder preference survives restart")
            call("xdotool", "mousemove", "219", "61", "click", "1")
            wait(lambda: selected_top("empty-hidden-again") == before, "The toggle hides empty folders again")
            names = {space["folder"]: space["name"] for space in app("ls")["spaces"]}
            assert names[str(main_tree)] == "Main name" and names[str(outside)] == "Feature name"
            assert not app("status")["errors"], app("status")
            print("PASS: repository-root grouping, native shortcuts, fold/reveal, config reload, and persistent empty-folder toggle.", flush=True)
        except Exception:
            print("Status:", app("status"), flush=True)
            call("herdr-app", "shot", str(root / "failure.png"))
            print((root / "app.log").read_text()[-8000:], flush=True)
            raise
        finally:
            try:
                app("do", "window.close")
                process.wait(timeout=5)
            finally:
                if process.poll() is None:
                    process.terminate()
                    process.wait(timeout=5)
                subprocess.run(["hc", "server", "stop"], env=env, timeout=5,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                xvfb.terminate()
                xvfb.wait(timeout=5)


if __name__ == "__main__":
    main()
