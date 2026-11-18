"""Exercise the project picker across two isolated cores using a local --via transport."""

import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[3]


def main():
    root = Path(tempfile.mkdtemp(prefix="herdr-remote-picker-", dir="/tmp/opencode"))
    print(f"Remote picker sandbox: {root}", flush=True)
    base = {k: os.environ[k] for k in ("PATH", "LANG", "USER", "LOGNAME", "TERM") if k in os.environ}

    def environment(name):
        env = dict(base)
        for key, folder in [("HOME", "home"), ("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                            ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "run")]:
            path = root / name / folder
            path.mkdir(parents=True, mode=0o700)
            env[key] = str(path)
        env.update(HERDR_APP_HOME=str(root / name / "app"), HC_SESSION=name,
                   HERDR_TELEMETRY="0", SHELL="/bin/sh", MANGOHUD="0")
        scripts = Path(env["HOME"]) / ".scripts"
        scripts.mkdir()
        for script in ("ls-project", "herdr-app-vim", "git-new-dated-worktree", "git-wt"):
            shutil.copyfile(ROOT / f"dot_scripts/executable_{script}", scripts / script)
            (scripts / script).chmod(0o700)
        env["PATH"] = f"{scripts}:{env['PATH']}"
        return env

    local, remote = environment("local"), environment("remote")
    app_home = Path(local["HERDR_APP_HOME"])
    shutil.copytree(ROOT / "dot_config/herdr-app", app_home)
    settings = json.loads((app_home / "settings.json").read_text())
    settings.update(core=shutil.which("hc"), telemetry=False, sounds={"enabled": False})
    (app_home / "settings.json").write_text(json.dumps(settings))
    (app_home / "shared.json").write_text(json.dumps({"frame.welcomed": "skipped"}))
    # Log rendered state only in this disposable copy, including actual keyboard events.
    mod = app_home / "mods/pbogut-projects/main.js"
    mod.write_text(mod.read_text().replace("  render() {", """  render() {
    console.log("PICKER_STATE " + JSON.stringify({
      machine: this.machine, query: this.query, loading: this.loading, error: this.error,
      folders: this.rows().map(row => row.folder), worktree: !!this.worktree,
    }));"""))
    for env in (local, remote):
        config = Path(env["HERDR_APP_HOME"]) / "mods/pbogut-projects/projects.json"
        config.parent.mkdir(parents=True, exist_ok=True)
        projects = Path(env["HOME"]) / "projects"
        (projects / "team/repo/.git").mkdir(parents=True)
        config.write_text(json.dumps({"root": str(projects), "aliases": {}}))
        (config.parents[2] / "herdr-project.json").write_text('{"tabs":["shell","nvim"]}')
    local_repo = Path(local["HOME"]) / "projects/team/repo"
    remote_repo = Path(remote["HOME"]) / "projects/team/repo"
    remote_app = Path(remote["HERDR_APP_HOME"])
    setup_runner = remote_app / "mods/pbogut-tabs/setup.sh"
    setup_runner.parent.mkdir(parents=True)
    shutil.copyfile(ROOT / "dot_config/herdr-app/mods/pbogut-tabs/setup.sh", setup_runner)
    shutil.copyfile(ROOT / "dot_config/herdr-app/mods/pbogut-tabs/teardown.sh", setup_runner.with_name("teardown.sh"))
    (remote_app / "setup fixture.sh").write_text(
        'printf "%s\\n" "$HERDR_PROJECT_DIR" "$HERDR_WORKTREE_DIR" "$PWD" >> "$HERDR_PROJECT_DIR/setup.log"\n')
    (remote_app / "teardown fixture.sh").write_text(
        'printf "%s\\n" "$HERDR_PROJECT_DIR" "$HERDR_WORKTREE_DIR" "$PWD" >> "$HERDR_PROJECT_DIR/teardown.log"\n')
    (remote_app / "herdr-project.json").write_text(json.dumps({
        "tabs": ["shell", "nvim"], "setup": {"script": "setup fixture.sh"},
        "teardown": {"script": "teardown fixture.sh"},
    }))

    def call(*args, env=local):
        result = subprocess.run(args, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=20)
        if result.returncode:
            raise RuntimeError(f"{args[:3]}: {result.stdout}")
        return result.stdout.strip()

    def app(*args):
        return json.loads(call("herdr-app", *args))

    # Use a real .bare project so Ctrl+Enter exercises the existing remote helpers.
    seed = root / "seed"
    call("git", "init", "-b", "main", str(seed), env=remote)
    call("git", "-C", str(seed), "-c", "user.name=Test", "-c", "user.email=test@example.com",
         "commit", "--allow-empty", "-m", "Initial", env=remote)
    (remote_repo / ".git").rmdir()
    call("git", "clone", "--bare", str(seed), str(remote_repo / ".bare"), env=remote)
    (remote_repo / ".git").write_text("gitdir: ./.bare\n")
    call("git", "-C", str(remote_repo), "update-ref", "refs/remotes/origin/main", "HEAD", env=remote)

    def wait(check, message):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if check():
                return
            time.sleep(0.05)
        raise AssertionError(message)

    def key(*keys):
        call("xdotool", "key", "--clearmodifiers", "--delay", "80", *keys)

    def state():
        records = [line.split("PICKER_STATE ", 1)[1] for line in (root / "app.log").read_text().splitlines()
                   if "PICKER_STATE " in line]
        return json.JSONDecoder().raw_decode(records[-1])[0] if records else {}

    def loaded(machine):
        value = state()
        return value.get("machine") == machine and value.get("loading") is False

    def space(machine, folder):
        return next((s for s in app("ls")["spaces"] if s["machine"] == machine and s["folder"] == str(folder)), None)

    xvfb = subprocess.Popen(["Xvfb", "-displayfd", "1", "-screen", "0", "1280x800x24", "-nolisten", "tcp"],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    local["DISPLAY"] = ":" + xvfb.stdout.readline().strip()
    process = None
    try:
        via = shlex.join(["env", "-i", *[f"{k}={v}" for k, v in remote.items()], "/bin/sh", "-c"])
        call("hc", "machine", "add", "--via", via, "--name", "fixture", "--session", "remote", "--json")
        with (root / "app.log").open("w") as log:
            process = subprocess.Popen(["herdr-app"], env=local, stdout=log, stderr=log)
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            call("xdotool", "windowfocus", window)
            app("do", "layout.switch", "--name", "pbogut")
            app("do", "space.new", "--folder", str(local_repo), "--machine", "")
            # A local space at the remote path must not intercept remote opening.
            app("do", "space.new", "--folder", str(remote_repo), "--machine", "")
            key("ctrl+alt+p")
            wait(lambda: loaded(None), "Local projects load")
            call("xdotool", "type", "--clearmodifiers", "team/repo")
            key("Tab")
            wait(lambda: loaded("fixture"), "Tab switches to the remote core while the input is focused")
            assert state()["query"] == "team/repo", state()
            assert state()["folders"] == [str(remote_repo)], state()
            call("herdr-app", "shot", str(root / "remote-picker.png"))
            key("shift+Tab")
            wait(lambda: loaded(None), "Shift+Tab cycles back to local")
            assert state()["query"] == "team/repo"
            key("Tab")
            wait(lambda: loaded("fixture"), "Tab reloads remote projects")
            key("Return")
            wait(lambda: space("fixture", remote_repo) is not None, "Enter creates a remote space")
            wait(lambda: [t["name"] for t in space("fixture", remote_repo)["tabs"]] == ["nvim", "shell"],
                 "Remote fallback configuration creates its named tabs in fixed order")
            editor = space("fixture", remote_repo)["tabs"][0]["terminals"][0]["terminal"]
            wait(lambda: "NVIM" in call("hc", "read", editor, "--lines", "0"), "Remote editor starts")
            assert space(None, remote_repo) is not None
            assert space("fixture", remote_repo)["active"]
            assert (remote_app / "setup.log").read_text().splitlines() == [
                str(remote_app), str(remote_repo), str(remote_repo),
            ], "The remote fallback setup runs with the remote config and working directory"
            key("ctrl+alt+p")
            wait(lambda: loaded("fixture"), "Reopening defaults to the active remote machine")
            assert state()["folders"].count(str(remote_repo)) == 1
            key("ctrl+Return")
            wait(lambda: state().get("worktree"), "Ctrl+Enter opens the remote worktree prompt")
            call("xdotool", "type", "--clearmodifiers", "remote feature")
            key("Return")
            branch = f"{call('date', '+%Y-%m-%d', env=remote)}-remote-feature"
            worktree = remote_repo / branch
            wait(lambda: space("fixture", worktree) is not None, "The new worktree opens on its remote machine")
            wait(lambda: [t["name"] for t in space("fixture", worktree)["tabs"]] == ["nvim", "shell"],
                 "The remote worktree uses the remote fallback tabs")
            assert call("git", "-C", str(worktree), "branch", "--show-current", env=remote) == branch
            assert space(None, worktree) is None
            assert (remote_app / "setup.log").read_text().splitlines()[3:] == [
                str(remote_app), str(worktree), str(worktree),
            ], "A sibling worktree runs its own setup on the remote machine"
            key("ctrl+alt+p")
            wait(lambda: loaded("fixture"), "The new worktree stays on the selected machine")
            # An invalid remote setting stays an error on that machine.
            remote_settings = Path(remote["HERDR_APP_HOME"]) / "mods/pbogut-projects/projects.json"
            remote_settings.write_text("{")
            key("Tab")
            wait(lambda: loaded(None), "Switch away before reloading invalid remote settings")
            key("Tab")
            wait(lambda: loaded("fixture") and state().get("error"), "Remote errors stay visible")
            assert str(local_repo) not in state()["folders"]
            key("Escape")
            app("do", f"pbogut-tabs.close-project@{space('fixture', worktree)['id']}")
            wait(lambda: space("fixture", worktree) is None, "Remote teardown closes only its own worktree space")
            assert (remote_app / "teardown.log").read_text().splitlines() == [
                str(remote_app), str(worktree), str(worktree),
            ], "Remote teardown uses the remote fallback and worktree directory"
            assert space("fixture", remote_repo) and space(None, remote_repo) and space(None, local_repo)
            assert not app("status")["errors"], app("status")
            print("PASS: native machine picker, remote tabs, setup/teardown, dated worktrees, focus and errors.", flush=True)
    except Exception:
        if process and process.poll() is None:
            print("Status:", app("status"), flush=True)
            print("Spaces:", app("ls"), flush=True)
            call("herdr-app", "shot", str(root / "failure.png"))
        if (root / "app.log").exists():
            print((root / "app.log").read_text()[-6000:], flush=True)
        raise
    finally:
        if process and process.poll() is None:
            process.terminate()
            process.wait(timeout=5)
        for env in (local, remote):
            subprocess.run(["hc", "server", "stop"], env=env, timeout=10,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        xvfb.terminate()
        xvfb.wait(timeout=5)


if __name__ == "__main__":
    main()
