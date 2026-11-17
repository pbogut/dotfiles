"""Check named-tab launches and exits in an isolated App, including Neovim and lazygit."""

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
    root = Path(tempfile.mkdtemp(prefix="herdr-named-tabs-", dir="/tmp/opencode"))
    print(f"Named-tab sandbox: {root}", flush=True)
    real_programs = {name: shutil.which(name) for name in ("nvim", "lazygit")}
    env = {key: value for key, value in os.environ.items()
           if not key.startswith(("HC_", "HERDR_")) and key not in ("WAYLAND_DISPLAY", "DBUS_SESSION_BUS_ADDRESS", "ZDOTDIR")}
    for key, name in [
        ("HOME", "home"), ("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
        ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "run"),
    ]:
        directory = root / name
        directory.mkdir(mode=0o700)
        env[key] = str(directory)
    bindir = root / "bin"
    bindir.mkdir()
    # The core prepends its own directory to PATH; keep fixture programs there too.
    shutil.copy2(shutil.which("hc"), bindir / "hc")
    env.update(HERDR_APP_HOME=str(root / "app"), HC_SESSION="named-tabs-test",
               HERDR_TELEMETRY="0", SHELL="/usr/bin/zsh", MANGOHUD="0",
               PATH=f"{bindir}:{env['PATH']}", ROLE_LOG=str(root / "roles.jsonl"))
    shutil.copytree(ROOT / "dot_config/herdr-app", root / "app")
    settings_path = root / "app/settings.json"
    settings = json.loads(settings_path.read_text())
    settings.update(core=str(bindir / "hc"), telemetry=False, sounds={"enabled": False})
    settings_path.write_text(json.dumps(settings))
    (root / "app/shared.json").write_text(json.dumps({"frame.welcomed": "skipped"}))
    (root / "home/.zshrc").write_text("# Suppress the first-run wizard in this test home.\n")
    for name in ("herdr-app-vim",):
        shutil.copyfile(ROOT / f"dot_scripts/executable_{name}", bindir / name)
        (bindir / name).chmod(0o700)
    fixture = bindir / "role-fixture"
    fixture.write_text(
        "#!/usr/bin/env python3\n"
        "import json,os,sys\n"
        "with open(os.environ['ROLE_LOG'], 'a') as log:\n"
        " log.write(json.dumps({'program': os.path.basename(sys.argv[0]), 'args': sys.argv[1:], "
        "'cwd': os.getcwd(), 'space': os.environ.get('HERDR_APP_SPACE_ID'), "
        "'legacy': os.environ.get('HERDR_ENV')}) + '\\n')\n"
        "print('ROLE-READY', flush=True)\n"
        "sys.exit(17 if input().strip() == 'fail' else 0)\n"
    )
    fixture.chmod(0o700)
    for name in ("nvim", "opencode", "lazygit", "lazydocker", "make", "draft", "rest"):
        (bindir / name).symlink_to(fixture)
    forbidden = bindir / "herdr"
    forbidden.write_text("#!/bin/sh\nprintf 'TUI called\\n' >> \"$ROLE_LOG\"\nexit 99\n")
    forbidden.chmod(0o700)
    # An inherited TUI environment must not send the dev tab to the old plugin.
    env["HERDR_ENV"] = "1"
    project = root / "project one"
    project.mkdir()
    (project / "subdirectory").mkdir()
    (project / "Makefile").write_text("dev:\n\t@true\n")
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

    def tabs(space):
        return next(item["tabs"] for item in app("ls")["spaces"] if item["id"] == space)

    def key(*keys):
        call("xdotool", "key", "--clearmodifiers", "--delay", "0", *keys)

    with (root / "app.log").open("w") as log:
        process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
        try:
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            call("xdotool", "windowfocus", window)
            app("do", "layout.switch", "--name", "pbogut")
            created = app("do", "space.new", "--name", "named-tabs-test", "--folder", str(project))
            space = created["space"]
            wait(lambda: app("status")["focused_pane"] is not None, "Initial focus")
            original = tabs(space)[0]
            original_terminal = original["terminals"][0]["terminal"]
            original_pid = json.loads(call("hc", "get", original_terminal, "--json"))["pid"]
            key(*(["alt+j"] * 12))
            wait(lambda: any(tab["name"] == "nvim" for tab in tabs(space)), "Alt+J creates nvim")
            wait(lambda: (root / "roles.jsonl").exists(), "Editor launches")
            assert len(tabs(space)) == 2, tabs(space)
            for shortcut, role in [
                ("alt+k", "shell"), ("alt+l", "shell-2"), ("alt+semicolon", "dev"),
                ("alt+m", "sql"), ("alt+comma", "rest"), ("alt+period", "git"),
                ("alt+h", "oc-1"), ("ctrl+alt+k", "oc-2"), ("ctrl+alt+l", "oc-3"), ("ctrl+alt+semicolon", "oc-4"),
            ]:
                key(shortcut)
                wait(lambda: any(tab["name"] == role for tab in tabs(space)), f"{shortcut} creates {role}")
                tab = next(tab for tab in tabs(space) if tab["name"] == role)
                wait(lambda: app("status")["tab"] == tab["id"], f"{shortcut} focuses {role}")
                if role == "shell":
                    shell = tab["terminals"][0]["terminal"]
                    call("hc", "send", shell, "cd subdirectory")
                    wait(lambda: json.loads(call("hc", "get", shell, "--json"))["foreground"]["cwd"] == str(project / "subdirectory"),
                         "Shell changes folder before the next tab is created")
            key("ctrl+alt+j", "alt+h", "alt+j")
            wait(lambda: len((root / "roles.jsonl").read_text().splitlines()) == 9, "Role programs launch once")
            records = [json.loads(line) for line in (root / "roles.jsonl").read_text().splitlines()]
            assert len([record for record in records if record["program"] == "nvim"]) == 1, records
            assert all(record["cwd"] == str(project) for record in records), records
            assert next(record for record in records if record["program"] == "make")["legacy"] is None
            assert json.loads(call("hc", "get", original_terminal, "--json"))["pid"] == original_pid
            assert [tab["name"] for tab in tabs(space)][:-1] == [
                "nvim", "shell", "shell-2", "dev", "sql", "rest", "git", "oc-1", "oc-2", "oc-3", "oc-4",
            ]
            editor = next(tab for tab in tabs(space) if tab["name"] == "nvim")
            second_project = root / "project two"
            second_project.mkdir()
            second_space = app("do", "space.new", "--folder", str(second_project))["space"]
            key("alt+j")
            wait(lambda: any(tab["name"] == "nvim" for tab in tabs(second_space)), "Second space has its own editor")
            wait(lambda: len((root / "roles.jsonl").read_text().splitlines()) == 10, "Second editor launches")
            second_editor = json.loads((root / "roles.jsonl").read_text().splitlines()[-1])
            assert second_editor["cwd"] == str(second_project) and second_editor["space"] == second_space
            assert len(tabs(space)) == 12 and len(tabs(second_space)) == 2
            subprocess.check_call(["bash", str(ROOT / "dot_scripts/executable_herdr-app-vim"), "--focus"],
                                  env={**env, "HERDR_APP_SPACE_ID": space}, timeout=10)
            wait(lambda: app("status")["tab"] == editor["id"], "Editor bridge targets its original space")
            app("do", "pbogut-tabs.docker")
            wait(lambda: any(tab["name"] == "docker" for tab in tabs(space)), "Docker tab launches")
            for target_space in (space, second_space):
                for tab in tabs(target_space):
                    if tab["name"] not in ("nvim", "dev", "sql", "rest", "git", "docker") and not tab["name"].startswith("oc-"):
                        continue
                    terminal = tab["terminals"][0]["terminal"]
                    wait(lambda: "ROLE-READY" in call("hc", "read", terminal, "--lines", "10"), f"{tab['name']} is ready to quit")
                    failed = tab["name"] == "oc-4"
                    call("hc", "send", terminal, "fail" if failed else "quit")
                    wait(lambda: all(item["id"] != tab["id"] for item in tabs(target_space)), f"{tab['name']} closes on program exit")
                    finished = json.loads(call("hc", "get", terminal, "--json"))
                    assert finished["state"] == "finished" and finished["exit_code"] == (17 if failed else 0), finished
            assert len(tabs(space)) == 3 and len(tabs(second_space)) == 1
            key("alt+j")
            wait(lambda: any(tab["name"] == "nvim" for tab in tabs(space)), "Shortcut recreates the exited editor")
            recreated = next(tab for tab in tabs(space) if tab["name"] == "nvim")
            assert recreated["id"] != editor["id"]
            terminal = recreated["terminals"][0]["terminal"]
            wait(lambda: "ROLE-READY" in call("hc", "read", terminal, "--lines", "10"), "Recreated editor starts")
            call("hc", "send", terminal, "quit")
            wait(lambda: len(tabs(space)) == 3, "Recreated editor closes on exit")

            # Repeat with actual TUI programs rather than only fixture processes.
            for name, executable in real_programs.items():
                assert executable, f"{name} is required for the native exit check"
                (bindir / name).unlink()
                (bindir / name).symlink_to(executable)
            call("git", "-C", str(project), "init", "--quiet")
            edit_file = project / "bridge file's.txt"
            edit_file.write_text("Open this in the named nvim tab.\n")
            config = root / "home/.config/lazygit"
            config.mkdir(parents=True)
            (config / "config.yml").write_text(
                "disableStartupPopups: true\nreporting: 'off'\nconfirmOnQuit: false\n"
                "gui:\n  showFileTree: false\ngit:\n  autoFetch: false\nupdate:\n  method: never\n"
            )
            shutil.copyfile(ROOT / "dot_config/lazygit/config-herdr-app.yml", config / "config-herdr-app.yml")
            (root / "home/.zshrc").write_text(
                f"source {shlex.quote(str(ROOT / 'dot_zshrc.d/functions/draft'))}\n")
            key("alt+m")
            wait(lambda: any(tab["name"] == "sql" for tab in tabs(space)), "Actual SQL editor tab appears")
            sql_tab = next(tab for tab in tabs(space) if tab["name"] == "sql")
            sql_terminal = sql_tab["terminals"][0]["terminal"]
            wait(lambda: ".sql" in call("hc", "read", sql_terminal, "--lines", "0"), "Actual draft sql runs Neovim")
            scratch = app("do", "tab.new", "--name", "scratch", "--argv", json.dumps(["exec", "nvim"]))
            wait(lambda: "NVIM" in call("hc", "read", scratch["terminal"], "--lines", "0"), "Another Neovim is running")
            other_pids = {}
            for terminal in (sql_terminal, scratch["terminal"]):
                wait(lambda: bool(json.loads(call("hc", "get", terminal, "--json")).get("foreground")), "Neovim process is reported")
                other_pids[terminal] = json.loads(call("hc", "get", terminal, "--json"))["foreground"]["pid"]
            for shortcut, role, ready_text, quit_keys in [
                ("alt+j", "nvim", "NVIM", ("Escape", "colon", "q", "a", "exclam", "Return")),
                ("alt+period", "git", edit_file.name, ("shift+q",)),
            ]:
                key(shortcut)
                wait(lambda: any(tab["name"] == role for tab in tabs(space)), f"Actual {role} tab appears")
                tab = next(tab for tab in tabs(space) if tab["name"] == role)
                terminal = tab["terminals"][0]["terminal"]
                wait(lambda: ready_text in call("hc", "read", terminal, "--lines", "0"), f"Actual {role} renders")
                wait(lambda: app("status")["tab"] == tab["id"], f"Actual {role} receives keyboard input")
                if role == "git":
                    key("2", "Down", "o")
                    wait(lambda: any(item["name"] == "nvim" for item in tabs(space)), "Lazygit creates the missing editor")
                    main_editor = next(item for item in tabs(space) if item["name"] == "nvim")
                    main_terminal = main_editor["terminals"][0]["terminal"]
                    wait(lambda: json.loads(call("hc", "get", main_terminal, "--json")).get("foreground", {}).get("name") == "nvim",
                         "Recreated editor runs Neovim")
                    editor_argv = json.loads(call("hc", "get", main_terminal, "--json"))["foreground"]["argv"]
                    editor_socket = editor_argv[editor_argv.index("--listen") + 1]
                    wait(lambda: call("nvim", "--server", editor_socket, "--remote-expr", "expand('%:p')") == str(edit_file),
                         "Lazygit opens the quoted file in the named editor")
                    wait(lambda: app("status")["tab"] == main_editor["id"], "File opening focuses the named editor")
                    for other_terminal, pid in other_pids.items():
                        info = json.loads(call("hc", "get", other_terminal, "--json"))
                        assert info["state"] == "live" and info["foreground"]["pid"] == pid, info
                    assert ".sql" in call("hc", "read", sql_terminal, "--lines", "0")
                    assert "NVIM" in call("hc", "read", scratch["terminal"], "--lines", "0")
                    app("do", "tab.select", "--id", tab["id"])
                    wait(lambda: app("status")["tab"] == tab["id"], "Return to lazygit to quit it")
                key(*quit_keys)
                wait(lambda: all(item["id"] != tab["id"] for item in tabs(space)), f"Quitting actual {role} closes its tab")
                assert json.loads(call("hc", "get", terminal, "--json"))["exit_code"] == 0
            assert not app("status")["errors"], app("status")
            print("PASS: named-tab shortcuts, close-on-exit, concurrent SQL/main/scratch Neovim, lazygit file opening and editor recreation.", flush=True)
        except Exception as error:
            if isinstance(error, subprocess.CalledProcessError):
                print(error.output, flush=True)
            print((root / "app.log").read_text()[-8000:], flush=True)
            print("Layout:", app("ls"), flush=True)
            print("Roles:", (root / "roles.jsonl").read_text() if (root / "roles.jsonl").exists() else "", flush=True)
            for item in app("ls")["spaces"]:
                for tab in item["tabs"]:
                    for terminal in tab["terminals"]:
                        print(tab["name"], call("hc", "read", terminal["terminal"], "--lines", "30"), flush=True)
                        print("Process:", call("hc", "get", terminal["terminal"], "--json"), flush=True)
            raise
        finally:
            try:
                app("do", "window.close")
                process.wait(timeout=5)
            except (subprocess.SubprocessError, TimeoutError):
                process.terminate()
                process.wait(timeout=5)
            subprocess.run(["hc", "server", "stop"], env=env, timeout=5,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            xvfb.terminate()
            xvfb.wait(timeout=5)


if __name__ == "__main__":
    main()
