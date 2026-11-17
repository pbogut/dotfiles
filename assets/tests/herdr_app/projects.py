"""Exercise project discovery and keyboard navigation in all three native pickers."""

import argparse
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", action="store_true", help="Measure three unfiltered openings with 600 projects")
    args = parser.parse_args()
    root = Path(tempfile.mkdtemp(prefix="herdr-project-picker-", dir="/tmp/opencode"))
    print(f"Project picker sandbox: {root}", flush=True)
    env = {key: value for key, value in os.environ.items()
           if not key.startswith(("HC_", "HERDR_")) and key not in ("WAYLAND_DISPLAY", "DBUS_SESSION_BUS_ADDRESS", "ZDOTDIR")}
    for key, name in [("HOME", "home"), ("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                      ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "run")]:
        (root / name).mkdir(mode=0o700)
        env[key] = str(root / name)
    env.update(HERDR_APP_HOME=str(root / "app"), HC_SESSION="project-picker-test",
               HERDR_TELEMETRY="0", SHELL="/bin/sh", MANGOHUD="0", PROJECTS=str(root / "wrong-root"))
    shutil.copytree(ROOT / "dot_config/herdr-app", root / "app")
    settings = json.loads((root / "app/settings.json").read_text())
    settings.update(core=shutil.which("hc"), telemetry=False, sounds={"enabled": False})
    (root / "app/settings.json").write_text(json.dumps(settings))
    (root / "app/shared.json").write_text(json.dumps({"frame.welcomed": "skipped"}))
    scripts = root / "home/.scripts"
    scripts.mkdir()
    for name in ("ls-project", "git-new-dated-worktree", "git-wt"):
        shutil.copyfile(ROOT / f"dot_scripts/executable_{name}", scripts / name)
        (scripts / name).chmod(0o700)
    env["PATH"] = f"{scripts}:{env['PATH']}"
    projects = root / "projects root"
    existing = projects / "gitlab.com/assuredpharmacy/existing"
    new = projects / "github.com/pbogut/alpha project's directory"
    scrolling = [projects / f"many/team/scroll-{index:03}" for index in range(598)]
    for path in (existing, new, *scrolling):
        (path / ".git").mkdir(parents=True)
    (existing / "subdirectory").mkdir()
    (root / "app/mods/pbogut-projects/projects.json").write_text(json.dumps({
        "root": str(projects), "aliases": {"github.com": "gh", "pbogut": "pb", "gitlab.com": "gl", "assuredpharmacy": "ap"},
    }))
    if args.profile:
        # Instrument only the disposable copy, keeping profiling out of the live mod.
        mod = root / "app/mods/pbogut-projects/main.js"
        source = mod.read_text()
        source = source.replace('    this.config =', '    this.profileStart = Date.now();\n    this.config =', 1)
        source = source.replace('        const result = await exec(', '        const execStart = Date.now();\n        const result = await exec(', 1)
        source = source.replace('        this.projects =', '        console.log("PICKER_PROFILE " + JSON.stringify({ phase: "exec", ms: Date.now() - execStart }));\n        this.projects =', 1)
        source = source.replace('  render() {', '  render() {\n    const renderStart = Date.now();', 1)
        source = source.replace('    return v_flex()\n      .id("projects")', '    const root = v_flex()\n      .id("projects")', 1)
        source = source.replace('(range) => rows.slice(range.start, range.end)', '''(range) => (
          console.log("PICKER_PROFILE " + JSON.stringify({ phase: "visible", total: rows.length, count: range.end - range.start })),
          rows.slice(range.start, range.end))''', 1)
        source = source.replace('.id("projects")', '''.on_size_change(() => {
        if (!this.loading) console.log("PICKER_PROFILE " + JSON.stringify({
          phase: "layout", count: this.projects.length, ms: Date.now() - this.profileStart,
        }));
      }).id("projects")''', 1)
        end = source.rfind("  }\n}")
        source = source[:end] + '''    console.log("PICKER_PROFILE " + JSON.stringify({
      phase: "render", count: rows.length, ms: Date.now() - renderStart,
    }));
    return root;
''' + source[end:]
        mod.write_text(source)
    xvfb = subprocess.Popen(["Xvfb", "-displayfd", "1", "-screen", "0", "1280x800x24", "-nolisten", "tcp"],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    env["DISPLAY"] = ":" + xvfb.stdout.readline().strip()

    def call(*args):
        return subprocess.check_output(args, env=env, text=True, stderr=subprocess.STDOUT, timeout=15).strip()

    def app(*args):
        return json.loads(call("herdr-app", *args))

    def wait(check, message):
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if check():
                return
            time.sleep(0.05)
        raise AssertionError(message)

    def key(*keys):
        call("xdotool", "key", "--clearmodifiers", "--delay", "80", *keys)

    def search(query, shortcut="ctrl+alt+p", mod="pbogut-projects"):
        key(shortcut)
        wait(lambda: mod in app("status")["overlays"], f"{shortcut} opens {mod}")
        call("xdotool", "type", "--clearmodifiers", "--delay", "20", query)

    def visible_row(name, color="#283457"):
        path = root / f"{name}.png"
        call("herdr-app", "shot", str(path))
        color = ImageColor.getrgb(color)
        with Image.open(path) as image:
            area = image.convert("RGB").crop(((image.width - 680) // 2, 130, (image.width + 680) // 2, image.height - 110))
            pixels = dict((rgb, count) for count, rgb in area.getcolors(area.width * area.height))
            return pixels.get(color, 0) > 10000

    with (root / "app.log").open("w") as log:
        process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
        try:
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            call("xdotool", "windowfocus", window)
            app("do", "layout.switch", "--name", "pbogut")
            original = app("do", "space.new", "--name", "Custom space", "--folder", str(existing))
            wait(lambda: app("status")["focused_pane"] is not None, "Initial shell is ready")
            if args.profile:
                def records():
                    return [
                        json.JSONDecoder().raw_decode(line.split("PICKER_PROFILE ", 1)[1])[0]
                        for line in (root / "app.log").read_text().splitlines() if "PICKER_PROFILE " in line
                    ]

                for attempt in range(3):
                    before = len(records())
                    start = time.perf_counter()
                    key("ctrl+alt+p")
                    wait(lambda: any(row["phase"] == "layout" and row["count"] == 600 for row in records()[before:]),
                         "The full project list reaches native layout")
                    call("herdr-app", "shot", str(root / f"profile-{attempt + 1}.png"))
                    phases = records()[before:]
                    print(json.dumps({"attempt": attempt + 1, "through_screenshot_ms": round((time.perf_counter() - start) * 1000),
                                      "phases": phases}), flush=True)
                    batches = [row["count"] for row in phases if row["phase"] == "visible" and row["total"] == 600]
                    assert batches and max(batches) <= 20, "Native layout renders only the visible rows of 600 projects"
                    key("Escape")
                assert not app("status")["errors"], app("status")
                return
            original_pid = json.loads(call("hc", "get", original["terminal"], "--json"))["pid"]
            call("hc", "send", original["terminal"], "cd subdirectory")
            wait(lambda: json.loads(call("hc", "get", original["terminal"], "--json")).get("foreground", {}).get("cwd") == str(existing / "subdirectory"),
                 "Shell changes directory before using the project picker")
            search("GH alpha")
            wait(lambda: visible_row("picker"), "The selected project row is visible")
            key("Return")
            wait(lambda: len(app("ls")["spaces"]) == 2, "Enter opens the project")
            opened = next(space for space in app("ls")["spaces"] if space["folder"] == str(new))
            assert opened["name"] == "gh󰿟pb󰿟alpha project's directory", opened
            assert app("status")["space"] == opened["id"]
            search("GL AP existing")
            key("Return")
            wait(lambda: app("status")["space"] == original["space"], "Aliases find and focus the existing space")
            assert len(app("ls")["spaces"]) == 2
            assert json.loads(call("hc", "get", original["terminal"], "--json"))["pid"] == original_pid
            search("not-a-project")
            key("Return")
            assert "pbogut-projects" in app("status")["overlays"]
            assert len(app("ls")["spaces"]) == 2
            key("Escape")
            wait(lambda: not app("status")["overlays"], "Escape closes the picker")
            listed = subprocess.check_output(["bash", str(ROOT / "dot_scripts/executable_ls-project"), "-f"],
                                             env={**env, "PROJECTS": str(projects)}, text=True).splitlines()
            scroll_paths = [path for path in listed if "/scroll-" in path]
            search("scroll-")
            key("ctrl+j", "Return")
            wait(lambda: any(space["folder"] == scroll_paths[1] and space["active"] for space in app("ls")["spaces"]),
                 "Ctrl+J selects the second project while searching")
            # The newly opened project now comes first.
            search("scroll-")
            key("ctrl+j", "ctrl+k", "Return")
            wait(lambda: not app("status")["overlays"], "Ctrl+K returns to the first project")
            assert next(space["folder"] for space in app("ls")["spaces"] if space["active"]) == scroll_paths[1]
            search("scroll-")
            key("ctrl+k")
            wait(lambda: visible_row("scrolled"), "Wrapping selection scrolls the last row into view")
            key("Return")
            wait(lambda: any(space["folder"] == scroll_paths[-1] and space["active"] for space in app("ls")["spaces"]),
                 "Enter opens the scrolled-to project")
            search("scroll-")
            key("ctrl+k")
            wait(lambda: visible_row("scrolled-click"), "The last virtual row is visible for clicking")
            with Image.open(root / "scrolled-click.png") as image:
                color = ImageColor.getrgb("#283457")
                pixels = image.convert("RGB")
                ys = [y for y in range(140, 480) if pixels.getpixel((850, y)) == color]
            call("xdotool", "mousemove", "--window", window, "850", str((min(ys) + max(ys)) // 2), "click", "1")
            wait(lambda: any(space["folder"] == scroll_paths[-2] and space["active"] for space in app("ls")["spaces"]),
                 "Clicking a virtual row opens its project after scrolling")
            call("xdotool", "windowsize", "--sync", window, "800", "600")
            search("custom space")
            wait(lambda: visible_row("resized"), "Picker rows are visible in a smaller window")
            call("xdotool", "mousemove", "--window", window, "400", "160", "click", "1")
            wait(lambda: app("status")["space"] == original["space"], "Click focuses an existing space")
            call("xdotool", "windowsize", "--sync", window, "1280", "800")
            call("xdotool", "mousemove", "--window", window, "20", "700")

            # Go to… keeps typing j/k as text and navigates with the input focused.
            for index in range(14):
                app("do", "tab.new", "--name", f"jk-navigation-{index:02}", "--space", original["space"])
            tabs = next(space["tabs"] for space in app("ls")["spaces"] if space["id"] == original["space"])
            choices = [tab for tab in tabs if tab["name"].startswith("jk-navigation-")]
            search("jk-navigation-", "alt+o", "pbogut-picker")
            key("ctrl+j", "Return")
            wait(lambda: app("status")["tab"] == choices[1]["id"], "Ctrl+J chooses the next tab")
            search("jk-navigation-", "alt+o", "pbogut-picker")
            key("ctrl+j", "ctrl+k", "Return")
            wait(lambda: app("status")["tab"] == choices[0]["id"], "Ctrl+K chooses the previous tab")
            search("jk-navigation-", "ctrl+shift+k", "pbogut-picker")
            key(*(["ctrl+j"] * 13))
            wait(lambda: visible_row("goto-scrolled", "#292e42"), "Go to… scrolls to the selected tab")
            key("Return")
            wait(lambda: app("status")["tab"] == choices[13]["id"], "Enter chooses the scrolled-to tab")

            # Compare the palette's long-list position using arrows and Ctrl+J/K.
            def palette_rows(name):
                call("herdr-app", "shot", str(root / f"{name}.png"))
                with Image.open(root / f"{name}.png") as image:
                    return image.convert("RGB").crop((380, 150, 900, 400)).tobytes()

            app("do", "app.palette")
            call("herdr-app", "shot", str(root / "palette-upstream.png"))
            key("Escape")
            search("", "ctrl+shift+p", "pbogut-palette")
            initial_rows = palette_rows("palette-initial")
            key(*(["Down"] * 21), "Up")
            arrow_rows = palette_rows("palette-arrows")
            assert arrow_rows != initial_rows, "Arrow keys scroll the palette"
            key("Escape")
            search("", "ctrl+shift+p", "pbogut-palette")
            key(*(["ctrl+j"] * 21), "ctrl+k")
            wait(lambda: palette_rows("palette-scrolled") == arrow_rows,
                 "Ctrl+J/K scroll to the same palette row as the arrow keys")
            key("Escape")

            def zoom():
                return app("status")["zoom"]

            search("zoom", "ctrl+shift+p", "pbogut-palette")
            key("ctrl+j", "Return")
            wait(lambda: zoom() < 1, "Ctrl+J and Enter run Zoom out")
            smaller = zoom()
            search("zoom", "ctrl+shift+p", "pbogut-palette")
            key("ctrl+j", "ctrl+k", "Return")
            wait(lambda: zoom() > smaller, "Ctrl+K and Enter run Zoom in")
            app("do", "app.zoom_reset")
            search("zoom out", "ctrl+shift+p", "pbogut-palette")
            key("Home", "Right", "ctrl+k", "Return")
            wait(lambda: zoom() < 1, "Ctrl+K preserves search text after the caret")
            app("do", "app.zoom_reset")
            search("not-a-command-jk", "ctrl+shift+p", "pbogut-palette")
            key("ctrl+j", "ctrl+k", "Return")
            assert "pbogut-palette" in app("status")["overlays"], "Empty results never run a command"
            key("Escape")
            search("go to space", "ctrl+shift+p", "pbogut-palette")
            key("Return")
            wait(lambda: "pbogut-picker" in app("status")["overlays"], "Palette opens the customized Go to…")
            key("Escape")

            # Real dated-worktree helpers, with a checkout newer than origin/main.
            repo = root / "dated-repo"
            call("git", "init", "--bare", "--initial-branch=main", str(repo / ".bare"))
            (repo / ".git").write_text("gitdir: ./.bare\n")
            tree = subprocess.check_output(["git", "-C", str(repo), "mktree"], input="", env=env, text=True).strip()

            def commit(message, *args):
                return call("git", "-C", str(repo), "-c", "user.name=Picker Test", "-c", "user.email=picker@example.invalid",
                            "commit-tree", tree, "-m", message, *args)

            base = commit("Base")
            other = commit("Other checkout", "-p", base)
            call("git", "-C", str(repo), "update-ref", "refs/heads/main", base)
            call("git", "-C", str(repo), "update-ref", "refs/remotes/origin/main", base)
            call("git", "-C", str(repo), "config", "remote.origin.url", str(root / "unused-origin"))
            call("git", "-C", str(repo), "config", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*")
            call("git", "-C", str(repo), "worktree", "add", "-b", "other", str(repo / "other"), other)
            app("do", "space.new", "--name", "Dated fixture", "--folder", str(repo / "other"))
            before = call("git", "-C", str(repo), "worktree", "list", "--porcelain")

            def dated_prompt():
                search("Dated fixture")
                key("ctrl+Return")
                assert "pbogut-projects" in app("status")["overlays"], "Ctrl+Enter keeps the native prompt open"

            dated_prompt()
            call("herdr-app", "shot", str(root / "dated-prompt.png"))
            key("Escape")
            assert call("git", "-C", str(repo), "worktree", "list", "--porcelain") == before, "Cancel creates no worktree"
            dated_prompt()
            name = f"{call('date', '+%Y-%m-%d')}-native-feature"
            target = repo / name
            call("xdotool", "type", "--clearmodifiers", "native feature")
            key("Return", "Return")
            wait(lambda: any(space["folder"] == str(target) and space["active"] for space in app("ls")["spaces"]),
                 "Enter creates the dated worktree and opens its space")
            assert call("git", "-C", str(target), "branch", "--show-current") == name
            assert call("git", "-C", str(target), "rev-parse", "HEAD") == base, "Helper branches from origin/main"
            assert len([space for space in app("ls")["spaces"] if space["folder"] == str(target)]) == 1

            dated_prompt()
            call("xdotool", "type", "--clearmodifiers", "bad..name")
            key("Return")

            def worktree_error():
                call("herdr-app", "shot", str(root / "dated-error.png"))
                with Image.open(root / "dated-error.png") as image:
                    colors = dict((rgb, count) for count, rgb in image.convert("RGB").crop((300, 40, 980, 500)).getcolors(680 * 460))
                    return colors.get(ImageColor.getrgb("#f7768e"), 0) > 25

            wait(worktree_error, "The helper's Git failure appears in the native prompt")
            assert not (repo / f"{call('date', '+%Y-%m-%d')}-bad..name").exists()
            key("ctrl+a")
            call("xdotool", "type", "--clearmodifiers", "retry success")
            key("Return")
            retry = repo / f"{call('date', '+%Y-%m-%d')}-retry-success"
            wait(lambda: any(space["folder"] == str(retry) and space["active"] for space in app("ls")["spaces"]),
                 "Correcting the branch name retries creation")
            assert not app("status")["errors"], app("status")
            print("PASS: 600-project picker, Ctrl+J/K, scrolling, mouse selection, and Ctrl+Enter dated worktrees with the real helpers.", flush=True)
        except Exception:
            print("Status:", app("status"), flush=True)
            print("Spaces:", app("ls"), flush=True)
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
