"""Check the desktop project launcher against an isolated Herdr App and core."""

import fcntl
import json
import os
from pathlib import Path
import pty
import shutil
import subprocess
import tempfile
import termios
import time

ROOT = Path(__file__).resolve().parents[3]


def main():
    root = Path(tempfile.mkdtemp(prefix="herdr-project-launcher-", dir="/tmp/opencode"))
    print(f"Project launcher sandbox: {root}", flush=True)
    env = {key: value for key, value in os.environ.items()
           if not key.startswith(("HC_", "HERDR_", "GIT_"))
           and key not in ("WAYLAND_DISPLAY", "DBUS_SESSION_BUS_ADDRESS", "ZDOTDIR")}
    for key, name in [("HOME", "home"), ("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                      ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "run")]:
        (root / name).mkdir(mode=0o700)
        env[key] = str(root / name)
    scripts = root / "home/.scripts"
    scripts.mkdir()
    projects = root / "projects"
    projects.mkdir()
    env.update(PATH=f"{scripts}:/usr/bin:/bin", HERDR_APP_HOME=str(root / "app"),
               HC_SESSION="project-launcher-test", HERDR_TELEMETRY="0", SHELL="/bin/sh", MANGOHUD="0",
               PROJECTS=str(projects), TERM="dumb", TEST_ROOT=str(root), PICK="alpha", PICK_STATUS="0",
               FZF_KEY="enter", BRANCH="launcher test")
    shutil.copytree(ROOT / "dot_config/herdr-app", root / "app",
                    ignore=shutil.ignore_patterns("encrypted_*"))
    (root / "app/settings.json").write_text(json.dumps({
        "core": shutil.which("hc"), "telemetry": False, "sounds": {"enabled": False},
    }))
    (root / "app/shared.json").write_text(json.dumps({"layout": "pbogut", "frame.welcomed": "skipped"}))
    # Load the real project controller without the desktop status publisher.
    (root / "app/layouts/pbogut.json").write_text(json.dumps({
        "type": "column", "children": [
            {"type": "block", "content": {"tab": "active"}},
            {"type": "block", "size": {"px": 0}, "content": {"mod": "pbogut-tabs"}},
        ],
    }))
    (root / "app/herdr-project.json").write_text(json.dumps({
        "tabs": ["shell", "shell-2"], "setup": {"script": "setup.sh"},
    }))
    (root / "app/setup.sh").write_text('printf "%s\\n" "$PWD" >> "$TEST_ROOT/setup.log"\n')
    for name in ("ls-project", "git-new-dated-worktree", "git-wt"):
        shutil.copyfile(ROOT / f"dot_scripts/executable_{name}", scripts / name)
        (scripts / name).chmod(0o700)
    template = (ROOT / "dot_scripts/executable_herdr-app-project.tmpl").read_text()
    launcher = scripts / "herdr-app-project"
    launcher.write_text(subprocess.check_output(
        ["chezmoi", "execute-template"],
        input='{{ with dict "dir_aliases" (dict "github.com" "gh" "pbogut" "pb") }}' + template + "{{ end }}",
        text=True, cwd=ROOT))
    launcher.chmod(0o700)

    def script(name, content):
        path = scripts / name
        path.write_text(content)
        path.chmod(0o700)

    picker = """#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
root = Path(os.environ["TEST_ROOT"])
rows = [row.split("\\0")[0] for row in sys.stdin.read().splitlines()]
(root / "picker.json").write_text(json.dumps({"args": sys.argv[1:], "rows": rows}))
status = int(os.environ["PICK_STATUS"])
if status in (0, 10):
    row = next(row for row in rows if os.environ["PICK"] in row)
    if Path(sys.argv[0]).name == "fzf":
        print(os.environ["FZF_KEY"])
    print(row)
sys.exit(status)
"""
    script("fuzzel", picker)
    script("fzf", picker)
    script("zenity", '#!/bin/sh\nprintf "%s\\n" "$BRANCH"\n')
    script("focus-or-exec", '#!/bin/sh\nprintf "%s\\n" "$*" >> "$TEST_ROOT/focus.log"\n')
    xvfb = subprocess.Popen(["Xvfb", "-displayfd", "1", "-screen", "0", "1280x800x24", "-nolisten", "tcp"],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    env["DISPLAY"] = ":" + xvfb.stdout.readline().strip()

    def call(*args, cwd=root, check=True):
        return subprocess.run(args, cwd=cwd, env=env, text=True, capture_output=True, timeout=20, check=check)

    def app(*args):
        return json.loads(call("herdr-app", *args).stdout)

    def wait(check, message):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            result = check()
            if result:
                return result
            time.sleep(0.05)
        raise AssertionError(message)

    def space_at(folder):
        return next((space for space in app("ls")["spaces"]
                     if space["folder"] == str(folder) and space["active"]), None)

    def ready(folder):
        space = space_at(folder)
        return space if space and [tab["name"] for tab in space["tabs"]] == ["shell", "shell-2"] else None

    def marked():
        return json.loads((root / "app/shared.json").read_text()).get("pbogut.projects.spaces", {})

    def launch():
        result = call(str(launcher), "gh alpha", check=False)
        assert result.returncode == 0, result.stderr
        return json.loads((root / "picker.json").read_text())

    try:
        alpha = projects / "github.com/pbogut/alpha project's $directory"
        ordinary = projects / "github.com/pbogut/ordinary"
        for path in (alpha, ordinary):
            (path / ".git").mkdir(parents=True)

        # Cancelling either picker must not open the app.
        for terminal, status in (("dumb", "1"), ("xterm-256color", "130")):
            env.update(TERM=terminal, PICK_STATUS=status)
            launch()
            assert call("herdr-app", "status", check=False).returncode != 0
            assert not (root / "focus.log").exists()
        env.update(TERM="dumb", PICK_STATUS="0")
        picker_state = launch()
        assert picker_state["args"] == ["--dmenu", "--no-sort", "--search", "gh alpha", "--cache", "/dev/null"]
        opened = wait(lambda: ready(alpha), "Cold launch opens the project and its configured tabs")
        wait(lambda: marked().get(opened["id"]), "New space receives the project marker")
        wait(lambda: (root / "focus.log").exists(), "Launcher focuses the app")
        assert (root / "focus.log").read_text().splitlines() == ["^herdr-app$ herdr-app"]
        assert opened["name"] == "gh󰿟pb󰿟alpha project's $directory"
        assert (root / "setup.log").read_text().splitlines() == [str(alpha)]

        # Ordinary spaces do not get an open badge or get converted into projects.
        plain = app("do", "space.new", "--name", "Ordinary", "--folder", str(ordinary))
        env.update(TERM="xterm-256color")
        picker_state = launch()
        assert picker_state["args"] == ["--expect=ctrl-n,enter", "-q", "gh alpha", "--height=100%"]
        assert picker_state["rows"][0].startswith("󰳆 ")
        assert sum("alpha" in row for row in picker_state["rows"]) == 1
        assert next(row for row in picker_state["rows"] if "ordinary" in row).startswith("  ")
        reused = wait(lambda: ready(alpha), "Existing project is focused again")
        assert reused["id"] == opened["id"] and reused["tabs"] == opened["tabs"]
        assert (root / "setup.log").read_text().splitlines() == [str(alpha)]
        assert len(app("ls")["spaces"]) == 2
        env.update(PICK="ordinary")
        launch()
        separate = wait(lambda: ready(ordinary), "Project opens beside the ordinary space")
        assert separate["id"] != plain["space"]
        assert not marked().get(plain["space"])

        # Use the actual dated-worktree helpers, including their error path.
        repo = projects / "github.com/pbogut/worktrees"
        repo.mkdir(parents=True)
        seed = root / "seed"
        call("git", "init", "--initial-branch=main", str(seed))
        call("git", "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
             "commit", "--allow-empty", "-m", "Initial", cwd=seed)
        call("git", "clone", "--bare", str(seed), str(repo / ".bare"))
        (repo / ".git").write_text("gitdir: ./.bare\n")
        call("git", "config", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*", cwd=repo)
        call("git", "fetch", "origin", cwd=repo)
        call("git", "worktree", "add", str(repo / "main"), "main", cwd=repo)
        env.update(TERM="dumb", PICK="worktrees", PICK_STATUS="10")
        launch()
        dated = repo / f"{time.strftime('%Y-%m-%d')}-launcher-test"
        wait(lambda: ready(dated), "Fuzzel's worktree action opens the new project")
        count = len(app("ls")["spaces"])
        result = call(str(launcher), check=False)
        assert result.returncode != 0 and "did not create a new worktree" in result.stderr
        assert len(app("ls")["spaces"]) == count

        # fzf's Ctrl+N prompts through the controlling terminal.
        env.update(TERM="xterm-256color", PICK_STATUS="0", FZF_KEY="ctrl-n")
        master, slave = pty.openpty()

        def terminal():
            os.setsid()
            fcntl.ioctl(slave, termios.TIOCSCTTY, 0)

        try:
            process = subprocess.Popen([str(launcher)], env=env, cwd=root, stdin=slave,
                                       stdout=slave, stderr=slave, preexec_fn=terminal)
            os.write(master, b"terminal branch\n")
            assert process.wait(timeout=20) == 0
        finally:
            os.close(master)
            os.close(slave)
        terminal_dated = repo / f"{time.strftime('%Y-%m-%d')}-terminal-branch"
        wait(lambda: ready(terminal_dated), "fzf's Ctrl+N opens the new project")
        assert not app("status")["errors"], app("status")
        script("herdr-app", "#!/bin/sh\nexit 1\n")
        script("sleep", "#!/bin/sh\nexit 0\n")
        env.update(TERM="dumb", PICK="alpha", PICK_STATUS="0")
        result = call(str(launcher), check=False)
        assert result.returncode != 0 and "Herdr App did not start" in result.stderr
        print("Passed: cancellation, cold start, aliases, quoted paths, fuzzel/fzf, project reuse, "
              "ordinary spaces, setup, dated-worktree success/failure, and startup failure.", flush=True)
    finally:
        call("/usr/bin/herdr-app", "do", "window.close", check=False)
        call("hc", "server", "stop", check=False)
        xvfb.terminate()
        xvfb.wait(timeout=5)


if __name__ == "__main__":
    main()
