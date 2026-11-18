"""Check the spaces picker, folder navigation, drag assignments, and persistence in an isolated Herdr window."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
from urllib.parse import quote

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
    # Observe rendered picker order and selection only in the disposable copy.
    picker = root / "app/mods/pbogut-space-picker/main.js"
    picker.write_text(picker.read_text().replace("    const height =", """    console.log("SPACE_PICKER " + JSON.stringify({
      query: this.query, selected: this.selected,
      rows: rows.map(row => ({ id: row.w.id, name: row.name, branch: row.branch })),
    }));
    const height ="""))

    def call(*args):
        return subprocess.check_output(args, env=env, text=True, stderr=subprocess.STDOUT, timeout=15).strip()

    def app(*args):
        return json.loads(call("herdr-app", *args))

    def open_project(name, folder):
        before = {space["id"] for space in app("ls")["spaces"]}
        request = quote(json.dumps({"label": name, "folder": str(folder)}), safe="")
        app("do", f"pbogut-tabs.project@{request}")
        def created():
            marked = json.loads((root / "app/shared.json").read_text()).get("pbogut.projects.spaces", {})
            return next((space["id"] for space in app("ls")["spaces"]
                         if space["id"] not in before and space["folder"] == str(folder) and marked.get(space["id"])), None)
        wait(created, "The project controller creates and marks its space")
        return created()

    def wait(check, message):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if check():
                return
            time.sleep(0.05)
        raise AssertionError(message)

    def key(*keys):
        call("xdotool", "key", "--clearmodifiers", "--delay", "80", *keys)

    def picker_state():
        records = [line.split("SPACE_PICKER ", 1)[1] for line in (root / "app.log").read_text().splitlines()
                   if "SPACE_PICKER " in line]
        return json.JSONDecoder().raw_decode(records[-1])[0] if records else {}

    def open_picker():
        key("alt+o")
        wait(lambda: "pbogut-space-picker" in app("status")["overlays"], "Alt+O opens the dedicated spaces picker")

    def drag(source_y, target_y):
        call("xdotool", "mousemove", "100", str(source_y), "mousedown", "1")
        call("xdotool", "mousemove", "100", str(target_y))
        call("xdotool", "mouseup", "1")

    def selected_top(name):
        path = root / f"{name}.png"
        call("herdr-app", "shot", str(path))
        selected = ImageColor.getrgb("#283457")
        with Image.open(path) as image:
            image = image.convert("RGB")
            return next((y for y in range(80, 650) if image.getpixel((10, y)) == selected), None)

    def row_top(space):
        app("do", "space.select", "--id", space)
        return selected_top("selected-row")

    def assignments():
        return json.loads((root / "app/shared.json").read_text()).get("pbogut.folders.assignments", {})

    def assignment_key(*parts):
        return json.dumps(parts, separators=(",", ":"))

    def drag_to_other(space, other_spaces):
        target = min(row_top(other) for other in other_spaces) - 14
        drag(row_top(space) + 10, target)

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
                opened[str(folder)] = open_project(name, folder) if folder in (main_tree, outside) else \
                    app("do", "space.new", "--name", name, "--folder", str(folder))["space"]
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
            open_picker()
            wait(lambda: picker_state().get("selected") == opened[str(personal)], "The picker starts on the current space")
            assert [row["id"] for row in picker_state()["rows"]] == [opened[folder] for folder in expected], \
                "The picker keeps sidebar order, including folded spaces"
            assert [row["name"] for row in picker_state()["rows"][:2]] == ["Pharmacy", "Pharmacy"]
            assert picker_state()["rows"][1]["branch"] == "2026-11-18-feature"
            call("herdr-app", "shot", str(root / "spaces-picker.png"))
            key("ctrl+k", "Return")
            wait(lambda: app("status")["space"] == opened[str(outside)] and not app("status")["overlays"],
                 "Ctrl+K and Enter switch to the previous, folded space")
            wait(lambda: selected_top("picker-revealed") is not None, "Selecting through the picker reveals the folder")
            open_picker()
            call("xdotool", "type", "--clearmodifiers", "Pharmacy")
            wait(lambda: picker_state().get("query") == "Pharmacy", "Typing filters by the sidebar project label")
            assert [row["id"] for row in picker_state()["rows"]] == [opened[str(main_tree)], opened[str(outside)]]
            key("ctrl+j", "Return")
            wait(lambda: not app("status")["overlays"], "Ctrl+J selects with the search field focused")
            assert app("status")["space"] == opened[str(outside)]
            open_picker()
            call("xdotool", "type", "--clearmodifiers", "Pharmacy")
            key("ctrl+j", "ctrl+k", "Return")
            wait(lambda: app("status")["space"] == opened[str(main_tree)], "Ctrl+K returns to the first filtered space")
            open_picker()
            call("xdotool", "type", "--clearmodifiers", "not-a-space-jk")
            key("ctrl+j", "ctrl+k", "Return")
            assert picker_state()["rows"] == []
            assert "pbogut-space-picker" in app("status")["overlays"], "Empty results cannot switch or create anything"
            key("Escape")
            wait(lambda: not app("status")["overlays"], "Escape closes the spaces picker")
            assert app("status")["space"] == opened[str(main_tree)]
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
            drag(120, 239)
            moved_order = [str(personal), str(main_tree), str(outside), str(notes)]
            wait(lambda: [s["folder"] for s in app("ls")["spaces"]] == moved_order,
                 "Dropping one worktree onto other moves both siblings")
            call("herdr-app", "shot", str(root / "manual-other.png"))

            app("do", "window.close")
            process.wait(timeout=5)
            process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            call("xdotool", "windowfocus", window)
            app("do", "layout.switch", "--name", "pbogut")
            wait(lambda: [s["folder"] for s in app("ls")["spaces"]] == moved_order, "Manual assignments survive App restart")
            for folder in (main_tree, outside):
                app("do", "space.close", json.dumps({"id": opened[str(folder)], "confirmed": True}))
            wait(lambda: len(app("ls")["spaces"]) == 2, "Close both worktree spaces")
            for folder in (main_tree, outside):
                old = opened[str(folder)]
                opened[str(folder)] = open_project("Restored space", folder)
                assert opened[str(folder)] != old
            app("do", "space.select", "--id", opened[str(main_tree)])
            wait(lambda: (selected_top("recreated-spaces") or 0) > 150,
                 "Recreated worktree spaces inherit the repository's manual group")
            # Preserve their current sibling order, which can settle differently
            # as each new project's Git lookup completes.
            expected = [space["folder"] for space in app("ls")["spaces"]
                        if space["folder"] in (str(main_tree), str(outside))] + [str(personal), str(notes)]
            top = selected_top("before-reset")
            call("xdotool", "mousemove", "100", str(top + 10), "click", "3")
            wait(lambda: "pbogut-spaces" in app("status")["overlays"], "The space context menu opens")
            call("herdr-app", "shot", str(root / "reset-menu.png"))
            key("Return")
            wait(lambda: [s["folder"] for s in app("ls")["spaces"]] == expected,
                 "Use matching rules restores both worktrees to work")
            wait(lambda: not app("status")["overlays"], "Reset closes the menu")

            # The same gesture works for a directory that is not a Git checkout.
            app("do", "space.select", "--id", opened[str(notes)])
            notes_before = selected_top("non-git-notes-before")
            app("do", "space.select", "--id", opened[str(personal)])
            drag(selected_top("non-git-source") + 10, 239)
            app("do", "space.select", "--id", opened[str(notes)])
            wait(lambda: selected_top("non-git-moved") == notes_before - 28,
                 "Moving the non-Git directory into other hides its now-empty personal header")

            # Ordinary spaces initially match the same root, but their moves are individual.
            scratch = app("do", "space.new", "--folder", str(main_tree))
            peer = app("do", "space.new", "--folder", str(main_tree))
            call("hc", "send", scratch["terminal"], f"cd {notes}")
            wait(lambda: next(s for s in app("ls")["spaces"] if s["id"] == scratch["space"])["name"] == notes.name,
                 "The ordinary space's stock name follows its live directory")
            project_key = assignment_key(None, str(project / ".bare"))
            scratch_key = assignment_key(None, "space", scratch["space"])
            drag_to_other(scratch["space"], [opened[str(notes)], opened[str(personal)]])
            wait(lambda: assignments().get(scratch_key) == "other", "An ordinary drop records only its space ID")
            assert project_key not in assignments(), "The ordinary drop must not move the repository"
            assert row_top(opened[str(main_tree)]) < row_top(scratch["space"])
            assert row_top(opened[str(outside)]) < row_top(scratch["space"])
            assert row_top(peer["space"]) < row_top(scratch["space"])
            work_spaces = {opened[str(main_tree)], opened[str(outside)], peer["space"]}
            app("do", "window.close")
            process.wait(timeout=5)
            process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            call("xdotool", "windowfocus", window)
            app("do", "layout.switch", "--name", "pbogut")
            wait(lambda: {s["id"] for s in app("ls")["spaces"][:3]} == work_spaces,
                 "The ordinary space's individual group survives restart")
            assert assignments().get(scratch_key) == "other"
            assert project_key not in assignments()

            # Moving a project leaves an unassigned ordinary peer in its original group.
            drag_to_other(opened[str(main_tree)], [scratch["space"], opened[str(notes)], opened[str(personal)]])
            wait(lambda: assignments().get(project_key) == "other", "The project still records a repository assignment")
            wait(lambda: app("ls")["spaces"][0]["id"] == peer["space"],
                 "The ordinary peer stays in work while both marked project worktrees move")
            assert row_top(peer["space"]) < row_top(opened[str(main_tree)])
            assert row_top(peer["space"]) < row_top(opened[str(outside)])
            fresh = app("do", "space.new", "--folder", str(main_tree))
            wait(lambda: {s["id"] for s in app("ls")["spaces"][:2]} == {peer["space"], fresh["space"]},
                 "A new ordinary space follows folder rules rather than the project's assignment")

            top = row_top(scratch["space"])
            call("xdotool", "mousemove", "100", str(top + 10), "click", "3")
            wait(lambda: "pbogut-spaces" in app("status")["overlays"], "The ordinary space's menu opens")
            key("Return")
            wait(lambda: scratch_key not in assignments(), "Reset clears only the ordinary space's assignment")
            assert assignments().get(project_key) == "other"
            wait(lambda: {s["id"] for s in app("ls")["spaces"][:3]} == {peer["space"], fresh["space"], scratch["space"]},
                  "Reset restores the ordinary space's opening-folder group without moving projects")
            for index in range(14):
                app("do", "space.new", "--name", f"picker-scroll-{index:02}", "--folder", str(notes))
            expected_ids = [space["id"] for space in app("ls")["spaces"]]
            open_picker()
            wait(lambda: [row["id"] for row in picker_state().get("rows", [])] == expected_ids,
                 "The picker follows sidebar order after additions and manual moves")
            call("xdotool", "type", "--clearmodifiers", "picker-scroll-")
            wait(lambda: len(picker_state()["rows"]) == 14, "All scrolling fixtures match")
            choices = [row["id"] for row in picker_state()["rows"]]
            key("Up")
            wait(lambda: picker_state()["selected"] == choices[-1], "Up wraps to the last space")
            path = root / "spaces-picker-scrolled.png"
            call("herdr-app", "shot", str(path))
            with Image.open(path) as image:
                pixels = image.convert("RGB")
                selected = ImageColor.getrgb("#283457")
                ys = [y for y in range(130, 480) if pixels.getpixel((850, y)) == selected]
            assert ys, "The selected row scrolls into view"
            call("xdotool", "mousemove", "--window", window, "850", str((min(ys) + max(ys)) // 2), "click", "1")
            wait(lambda: not app("status")["overlays"], "Clicking the scrolled row selects its space")
            assert app("status")["space"] == choices[-1]
            open_picker()
            key("Down", "Return")
            wait(lambda: not app("status")["overlays"], "Down wraps from the last space to the first")
            assert app("status")["space"] == expected_ids[0]
            key("ctrl+shift+k")
            wait(lambda: "pbogut-picker" in app("status")["overlays"], "Ctrl+Shift+K opens Go to")
            key("Escape")
            assert not app("status")["errors"], app("status")
            print("PASS: spaces picker order/search/keyboard/scrolling, grouping, drag isolation, persistence, and scoped reset.", flush=True)
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
