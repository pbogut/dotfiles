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
    for name in ("ls-project", "git-new-dated-worktree", "git-wt", "herdr-app-vim"):
        shutil.copyfile(ROOT / f"dot_scripts/executable_{name}", scripts / name)
        (scripts / name).chmod(0o700)
    env["PATH"] = f"{scripts}:{env['PATH']}"
    env["DEV_LOG"] = str(root / "dev.jsonl")
    dev_script = scripts / "dev fixture.py"
    dev_script.write_text(
        "import json,os,sys\n"
        "with open(os.environ['DEV_LOG'], 'a') as log:\n"
        " log.write(json.dumps({'args': sys.argv[1:], 'cwd': os.getcwd()}) + '\\n')\n"
        "print('DEV-READY', flush=True)\n"
        "sys.exit(17 if input().strip() == 'fail' else 0)\n"
    )
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

    def dev_records(folder):
        path = root / "dev.jsonl"
        records = [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []
        return [record for record in records if record["cwd"] == str(folder)]

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
            wait(lambda: any(space["id"] == opened["id"] and [tab["name"] for tab in space["tabs"]] == ["nvim"]
                             for space in app("ls")["spaces"]),
                 "A project without a definition opens the default Neovim tab")
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

            defaults = root / "app/herdr-project.json"
            default_source = defaults.read_text()
            defaults.write_text(json.dumps({"tabs": ["shell", "dev"], "dev": ["python3", str(dev_script), "fallback"]}))
            search(Path(scroll_paths[4]).name)
            key("Return")
            wait(lambda: any(space["folder"] == scroll_paths[4] and [tab["name"] for tab in space["tabs"]] == ["shell", "dev"]
                             for space in app("ls")["spaces"]),
                 "Editing the fallback definition changes the next project's default tabs")
            wait(lambda: dev_records(scroll_paths[4]), "The fallback dev command launches")
            assert dev_records(scroll_paths[4]) == [{"cwd": scroll_paths[4], "args": ["fallback"]}]
            defaults.write_text(default_source)
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
            definition = repo / "herdr-project.json"
            shutil.copyfile(dev_script, repo / dev_script.name)
            dev_args = ["two words", "quote's", "$(touch must-not-exist)", "*", "", "line\nbreak"]
            dev_command = ["python3", "../dev fixture.py", *dev_args]
            configured_tabs = ["shell-2", "nvim", "shell", "dev"]
            ordered_tabs = ["nvim", "shell", "shell-2", "dev"]
            project_config = {"tabs": configured_tabs, "dev": dev_command}
            definition.write_text(json.dumps(project_config))
            dated = app("do", "space.new", "--name", "Dated fixture", "--folder", str(repo / "other"))
            dated_pid = json.loads(call("hc", "get", dated["terminal"], "--json"))["pid"]

            def project_space(folder):
                return next((space for space in app("ls")["spaces"] if space["folder"] == str(folder)), None)

            def tab_names(folder):
                space = project_space(folder)
                return [tab["name"] for tab in space["tabs"]] if space else []

            def editor_pid(folder):
                tab = next(tab for tab in project_space(folder)["tabs"] if tab["name"] == "nvim")
                return json.loads(call("hc", "get", tab["terminals"][0]["terminal"], "--json"))["pid"]

            search("Dated fixture")
            key("Return")
            wait(lambda: tab_names(repo / "other")[:4] == ordered_tabs, "Existing space gets its JSON tabs in fixed order")
            assert len(project_space(repo / "other")["tabs"]) == 5, "An existing space keeps its original tab"
            wait(lambda: dev_records(repo / "other"), "The configured dev command launches")
            assert dev_records(repo / "other") == [{"cwd": str(repo / "other"), "args": dev_args}]
            assert not (repo / "other/must-not-exist").exists(), "Arguments are not evaluated by a shell"
            assert app("status")["tab"] == dated["tab"], "Applying tabs preserves existing selection"
            assert json.loads(call("hc", "get", dated["terminal"], "--json"))["pid"] == dated_pid
            editor = editor_pid(repo / "other")
            search("Dated fixture")
            key("Return")
            wait(lambda: not app("status")["overlays"], "Reopening an existing project finishes")
            assert editor_pid(repo / "other") == editor, "Reopening focuses the running editor instead of restarting it"
            assert len(dev_records(repo / "other")) == 1, "Reopening reuses the running dev process"
            shell = next(tab for tab in project_space(repo / "other")["tabs"] if tab["name"] == "shell")
            app("do", "tab.close", "--id", shell["id"])
            wait(lambda: "shell" not in tab_names(repo / "other"), "The configured shell closes")
            search("Dated fixture")
            key("Return")
            wait(lambda: tab_names(repo / "other")[:4] == ordered_tabs, "Reopening fills a missing configured tab")
            assert editor_pid(repo / "other") == editor
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
            wait(lambda: tab_names(target) == ordered_tabs, "The new dated worktree uses fixed tab order")
            first_configured = next(tab for tab in project_space(target)["tabs"] if tab["name"] == configured_tabs[0])
            assert app("status")["tab"] == first_configured["id"], "The first configured tab is selected"
            nvim_tab = next(tab for tab in project_space(target)["tabs"] if tab["name"] == "nvim")
            nvim_terminal = nvim_tab["terminals"][0]["terminal"]
            wait(lambda: "NVIM" in call("hc", "read", nvim_terminal, "--lines", "0"), "The configured editor runs real Neovim")
            assert json.loads(call("hc", "get", nvim_terminal, "--json"))["cwd"] == str(target)
            wait(lambda: dev_records(target), "The dated worktree launches its own dev command")
            assert dev_records(target) == [{"cwd": str(target), "args": dev_args}]
            dev_tab = next(tab for tab in project_space(target)["tabs"] if tab["name"] == "dev")
            dev_terminal = dev_tab["terminals"][0]["terminal"]
            wait(lambda: "DEV-READY" in call("hc", "read", dev_terminal, "--lines", "10"), "Dev is ready")
            definition.write_text(json.dumps({**project_config, "dev": [*dev_command, "refreshed"]}))
            key("alt+semicolon")
            wait(lambda: app("status")["tab"] == dev_tab["id"], "Alt+; focuses the existing dev tab")
            assert len(dev_records(target)) == 1, "Changing the configuration does not restart an existing tab"
            call("hc", "send", dev_terminal, "fail")
            wait(lambda: "dev" not in tab_names(target), "A failed custom command closes its dev tab")
            assert json.loads(call("hc", "get", dev_terminal, "--json"))["exit_code"] == 17
            key(*(["alt+semicolon"] * 10))
            wait(lambda: len(dev_records(target)) == 2, "Alt+; reloads the command when recreating dev")
            assert dev_records(target)[1]["args"] == [*dev_args, "refreshed"]
            assert tab_names(target).count("dev") == 1, "Repeated shortcuts create only one dev tab"
            definition.write_text(json.dumps(project_config))
            app("do", "pbogut-tabs.shell-3")
            wait(lambda: tab_names(target) == [*ordered_tabs, "shell-3"], "Named shortcuts preserve fixed order")

            selected = next(tab for tab in project_space(target)["tabs"] if tab["name"] == "shell-3")["id"]
            wait(lambda: app("status")["tab"] == selected, "The shortcut finishes selecting shell-3 before reload")
            dev_tab = next(tab for tab in project_space(target)["tabs"] if tab["name"] == "dev")
            app("do", "tab.move", "--id", dev_tab["id"], "--index", "1")
            wait(lambda: tab_names(target)[0] == "dev", "The fixture starts with an old project-specific order")
            reloaded_tabs = ["dev", "shell", "nvim", "shell-2"]
            definition.write_text(json.dumps({
                "name": "Reloaded project", "tabs": reloaded_tabs, "dev": [*dev_command, "manual reload"],
            }))
            search("reload project config", "ctrl+shift+p", "pbogut-palette")
            key("Return")
            wait(lambda: tab_names(target) == [*ordered_tabs, "shell-3"],
                 "Reload restores fixed order regardless of the project's list order")
            assert app("status")["tab"] == selected, "Reload preserves the selected tab"
            assert len(dev_records(target)) == 2, "Reload keeps an already running dev command"
            assert tab_names(repo / "other")[:4] == ordered_tabs, "Sibling worktree tabs keep fixed order"
            definition.write_text('{"name":"Invalid","tabs":["nvim"],"dev":[]}')
            app("do", "pbogut-tabs.reload-project")
            # A harmless following request runs only after reload has finished validating.
            app("do", "pbogut-tabs.shell-2")
            shell_two = next(tab for tab in project_space(target)["tabs"] if tab["name"] == "shell-2")["id"]
            wait(lambda: app("status")["tab"] == shell_two, "The reload queue remains usable after an error")
            assert tab_names(target) == [*ordered_tabs, "shell-3"], "Invalid config retains fixed order"
            definition.write_text(json.dumps({
                "name": "Reloaded project", "tabs": reloaded_tabs, "dev": [*dev_command, "manual reload"],
            }))
            dev_tab = next(tab for tab in project_space(target)["tabs"] if tab["name"] == "dev")
            app("do", "tab.close", "--id", dev_tab["id"])
            wait(lambda: "dev" not in tab_names(target), "Dev closes before applying its new command")
            search("reload project config", "ctrl+shift+p", "pbogut-palette")
            key("Return")
            wait(lambda: len(dev_records(target)) == 3, "Reload recreates missing dev with the new command")
            assert dev_records(target)[-1]["args"] == [*dev_args, "manual reload"]
            definition.write_text(json.dumps(project_config))
            app("do", "pbogut-tabs.reload-project")
            wait(lambda: tab_names(target) == [*ordered_tabs, "shell-3"], "Reload preserves fixed tab order")

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
            wait(lambda: tab_names(retry) == ordered_tabs, "Sibling worktrees share the same definition")

            definition.write_text('{"tabs":["nvim","unknown-role"]}')
            dated_prompt()
            call("xdotool", "type", "--clearmodifiers", "invalid definition")
            key("Return")
            invalid = repo / f"{call('date', '+%Y-%m-%d')}-invalid-definition"
            wait(lambda: project_space(invalid) is not None, "A bad definition still opens the project")
            assert len(project_space(invalid)["tabs"]) == 1
            assert tab_names(invalid) == ["1"], "Validation prevents a partial tab layout"
            definition.write_text(json.dumps(project_config))
            search("invalid-definition")
            key("Return")
            wait(lambda: tab_names(invalid)[:4] == ordered_tabs, "Reopening reloads the corrected definition")

            hook = repo / "setup's script.sh"
            hook.write_text(
                'printf "%s\\n" "$HERDR_PROJECT_DIR" "$HERDR_WORKTREE_DIR" "$PWD" >> "$HERDR_PROJECT_DIR/setup.log"\n'
                'echo SETUP-READY\nread -r answer\n[[ $answer != fail ]] || exit 17\n'
                'touch "$HERDR_WORKTREE_DIR/.setup-ready"\n')
            setup_config = {"tabs": ["shell", "dev"], "dev": dev_command,
                            "setup": {"version": 1, "script": hook.name}}
            definition.write_text(json.dumps(setup_config))
            dated_prompt()
            call("xdotool", "type", "--clearmodifiers", "setup feature")
            key("Return")
            setup_tree = repo / f"{call('date', '+%Y-%m-%d')}-setup-feature"
            wait(lambda: "setup" in tab_names(setup_tree), "A new project opens a visible setup tab first")

            def setup_terminal():
                tab = next(tab for tab in project_space(setup_tree)["tabs"] if tab["name"] == "setup")
                terminal = tab["terminals"][0]["terminal"]
                wait(lambda: "SETUP-READY" in call("hc", "read", terminal, "--lines", "20"),
                     "Setup displays progress and waits for input")
                return terminal

            first_setup = setup_terminal()
            assert "shell" not in tab_names(setup_tree) and "dev" not in tab_names(setup_tree)
            assert (repo / "setup.log").read_text().splitlines() == [str(repo), str(setup_tree), str(setup_tree)]
            search("setup-feature")
            key("Return")
            assert setup_terminal() == first_setup, "Reopening focuses the same running setup"
            app("do", f"pbogut-tabs.shell-3@{dated['space']}")
            wait(lambda: "shell-3" in tab_names(repo / "other"), "Interactive setup does not block other spaces")
            call("hc", "send", first_setup, "fail")
            wait(lambda: "Setup failed (exit 17)" in call("hc", "read", first_setup, "--lines", "20"),
                 "Failed setup keeps its output visible")
            assert "dev" not in tab_names(setup_tree)
            search("setup-feature")
            key("Return")
            wait(lambda: any(tab["name"] == "setup" and tab["terminals"][0]["terminal"] != first_setup
                             for tab in project_space(setup_tree)["tabs"]), "Reopening retries a failed setup")
            second_setup = setup_terminal()
            call("hc", "send", second_setup, "continue")
            wait(lambda: "setup" not in tab_names(setup_tree) and "dev" in tab_names(setup_tree),
                 "Success closes setup and opens configured tabs")
            wait(lambda: dev_records(setup_tree), "Dev starts after successful setup")
            assert (setup_tree / ".setup-ready").exists()
            assert len((repo / "setup.log").read_text().splitlines()) == 6, "The failed run was not cached"

            dev_tab = next(tab for tab in project_space(setup_tree)["tabs"] if tab["name"] == "dev")
            app("do", "tab.close", "--id", dev_tab["id"])
            wait(lambda: "dev" not in tab_names(setup_tree), "Dev closes before the next setup version")
            before_setup = app("status")["tab"]
            setup_config["setup"]["version"] = 2
            definition.write_text(json.dumps(setup_config))
            app("do", "pbogut-tabs.reload-project")
            wait(lambda: "setup" in tab_names(setup_tree), "A new setup version runs before filling missing tabs")
            version_two = setup_terminal()
            assert "dev" not in tab_names(setup_tree)
            call("hc", "send", version_two, "continue")
            wait(lambda: "setup" not in tab_names(setup_tree) and len(dev_records(setup_tree)) == 2,
                 "Version two completes and recreates dev")
            assert app("status")["tab"] == before_setup, "Successful setup restores the previous tab"
            dev_tab = next(tab for tab in project_space(setup_tree)["tabs"] if tab["name"] == "dev")
            app("do", "tab.close", "--id", dev_tab["id"])
            app("do", "window.close")
            process.wait(timeout=5)
            process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            app("do", "layout.switch", "--name", "pbogut")
            app("do", "space.select", "--id", project_space(setup_tree)["id"])
            app("do", "pbogut-tabs.reload-project")
            wait(lambda: len(dev_records(setup_tree)) == 3, "Saved setup completion survives an App restart")
            assert len((repo / "setup.log").read_text().splitlines()) == 9, "Successful versions run once"
            assert "setup" not in tab_names(setup_tree)
            assert not app("status")["errors"], app("status")
            print("PASS: project pickers, JSON tabs/dev, interactive setup ordering, failure retry, versioning, and restart persistence.", flush=True)
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
