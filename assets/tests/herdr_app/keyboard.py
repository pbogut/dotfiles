"""Exercise Herdr shortcuts in a disposable X11 window and core session."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


SOURCE = Path(__file__).resolve().parents[3] / "dot_config/herdr-app"


def main():
    root = Path(tempfile.mkdtemp(prefix="herdr-keyboard-", dir="/tmp/opencode"))
    print(f"Sandbox and screenshots: {root}", flush=True)
    env = {
        key: value for key, value in os.environ.items()
        if not key.startswith(("HC_", "HERDR_"))
        and key not in ("WAYLAND_DISPLAY", "DBUS_SESSION_BUS_ADDRESS")
    }
    for key, name in [
        ("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
        ("XDG_DATA_HOME", "data"), ("XDG_STATE_HOME", "state"),
        ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "run"),
    ]:
        directory = root / name
        directory.mkdir(mode=0o700)
        env[key] = str(directory)
    env.update(
        HERDR_APP_HOME=str(root / "app"), HC_SESSION="keyboard-test",
        HERDR_TELEMETRY="0", SHELL="/bin/sh", MANGOHUD="0",
    )
    shutil.copytree(SOURCE, root / "app")
    settings_path = root / "app/settings.json"
    settings = json.loads(settings_path.read_text())
    settings.update(core=shutil.which("hc"), telemetry=False, sounds={"enabled": False})
    settings_path.write_text(json.dumps(settings))
    (root / "app/shared.json").write_text(json.dumps({"frame.welcomed": "skipped"}))
    xvfb = subprocess.Popen(
        ["Xvfb", "-displayfd", "1", "-screen", "0", "1280x800x24", "-nolisten", "tcp"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
    )
    env["DISPLAY"] = ":" + xvfb.stdout.readline().strip()

    def call(*args):
        return subprocess.check_output(
            args, env=env, text=True, stderr=subprocess.STDOUT, timeout=15,
        ).strip()

    def app(*args):
        return json.loads(call("herdr-app", *args))

    def wait_for(check, description):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            if check():
                return
            time.sleep(0.05)
        raise AssertionError(description)

    def key(*keys):
        call("xdotool", "key", "--clearmodifiers", "--delay", "80", *keys)

    def terminal_ready(terminal):
        # Pane creation returns before the app receives the core's terminal list.
        try:
            app("do", "terminal.select", "--terminal", terminal)
            app("do", "terminal.clear_selection", "--terminal", terminal)
            return True
        except subprocess.CalledProcessError:
            return False

    def bar_open():
        return "pbogut-keys" in app("status")["overlays"]

    with (root / "app.log").open("w") as log:
        process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
        try:
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            call("xdotool", "windowfocus", window)
            app("do", "layout.switch", "--name", "pbogut")
            app("do", "space.new", "--name", "keyboard-test", "--folder", str(root / "home"))
            wait_for(lambda: app("status")["focused_pane"] is not None, "Initial terminal focus")
            assert app("status")["overlays"] == []

            key("ctrl+g")
            wait_for(bar_open, "Ctrl+G opens the bottom overlay")
            call("herdr-app", "shot", str(root / "prefix.png"))
            key("c")
            wait_for(lambda: len(app("ls")["spaces"][0]["tabs"]) == 2, "Prefix+c creates a tab")
            wait_for(lambda: not bar_open(), "New tab closes the bar")
            assert app("status")["overlays"] == []
            key("ctrl+g", "v")
            wait_for(
                lambda: len(app("ls")["spaces"][0]["tabs"][1]["terminals"]) == 2,
                "Prefix+v splits the tab",
            )
            wait_for(lambda: not bar_open(), "Right split closes the bar")
            key("ctrl+g", "s")
            wait_for(
                lambda: len(app("ls")["spaces"][0]["tabs"][1]["terminals"]) == 3,
                "Prefix+s splits down",
            )
            wait_for(lambda: not bar_open(), "Down split closes the bar")
            before = app("status")
            key("ctrl+g", "g", "h", "p", "n", "y", "ctrl+y", "ctrl+k", "shift+s", "ctrl+shift+d", "1", "x")
            after = app("status")
            assert after["overlays"] == ["pbogut-keys"], after
            for field in ("space", "tab", "focused_pane"):
                assert after[field] == before[field], field
            assert len(app("ls")["spaces"][0]["tabs"][1]["terminals"]) == 3
            key("Escape")
            wait_for(lambda: not bar_open(), "Escape cancels prefix mode")
            key("ctrl+g", "ctrl+g")
            wait_for(lambda: not bar_open(), "Ctrl+G toggles the bar off")

            # An exact known screen and a waiting program make clipboard checks deterministic.
            copy = app("do", "tab.new", "--name", "copy-test", "--argv", json.dumps([
                "sh", "-c", "printf '\\033[2J\\033[3J\\033[Habcdefghij'; read -r line",
            ]))
            terminal = copy["terminal"]
            wait_for(lambda: "abcdefghij" in call("hc", "read", terminal, "--lines", "0"), "Copy fixture output")
            wait_for(lambda: terminal_ready(terminal), "Copy terminal available to app commands")
            key("alt+Escape")
            wait_for(lambda: "pbogut-copy" in app("status")["overlays"], "Alt+Esc opens copy mode directly")
            key("Home", "v", "Right", "Right")
            call("herdr-app", "shot", str(root / "copy.png"))
            key("y")
            wait_for(lambda: not app("status")["overlays"], "Y copies and leaves copy mode")
            assert call("xclip", "-selection", "clipboard", "-o") == "abc"
            key("alt+Escape", "Escape")
            wait_for(lambda: not app("status")["overlays"], "Escape leaves copy mode")
            key("alt+Escape", "alt+Escape")
            wait_for(lambda: not app("status")["overlays"], "Alt+Esc toggles copy mode off")

            # Read actual bytes to catch focus leaks that command/state checks miss.
            raw = app("do", "tab.new", "--name", "focus-test", "--argv", json.dumps([
                "python3", "-u", "-c",
                "import os,signal,tty; tty.setraw(0)\n"
                "signal.signal(signal.SIGWINCH, lambda *_: print('RESIZE:' + str(os.get_terminal_size()), flush=True))\n"
                "print('RAW-READY', os.get_terminal_size(), flush=True)\n"
                "while True: print('BYTE:' + os.read(0, 1).hex(), flush=True)",
            ]))
            terminal = raw["terminal"]
            wait_for(lambda: "RAW-READY" in call("hc", "read", terminal, "--lines", "0"), "Raw fixture ready")
            key("ctrl+g", "z")
            wait_for(bar_open, "Bar opens over the raw terminal")
            call("herdr-app", "shot", str(root / "overlay.png"))
            key("Escape", "a")
            wait_for(lambda: "BYTE:61" in call("hc", "read", terminal, "--lines", "0"), "Escape restores typing")
            key("ctrl+g", "ctrl+g", "b")
            wait_for(lambda: "BYTE:62" in call("hc", "read", terminal, "--lines", "0"), "Double Ctrl+G restores typing")
            key("ctrl+g")
            wait_for(bar_open, "Bar reopens before outside click")
            call("xdotool", "mousemove", "--window", window, "400", "200", "click", "1")
            wait_for(lambda: not bar_open(), "Clicking the terminal closes the bar")
            key("c")
            wait_for(lambda: "BYTE:63" in call("hc", "read", terminal, "--lines", "0"), "Outside click restores typing")
            output = call("hc", "read", terminal, "--lines", "0")
            assert all("BYTE:" + byte not in output for byte in ("07", "1b", "7a")), output
            assert "RESIZE:" not in output, output
            assert not bar_open()

            app("do", "app.zoom_in")
            key("ctrl+g")
            wait_for(bar_open, "Bar opens at the new zoom")
            call("herdr-app", "shot", str(root / "zoomed.png"))
            key("Escape")
            app("do", "app.zoom_reset")
            key("alt+t", "ctrl+g")
            wait_for(bar_open, "Bar opens with the sidebar hidden")
            call("herdr-app", "shot", str(root / "no-sidebar.png"))
            key("Escape")

            assert not app("status")["errors"], app("status")
            print("PASS: bottom overlay without terminal resize, c/v/s actions, restored typing, and Alt+Esc clipboard copy.", flush=True)
        except Exception:
            print((root / "app.log").read_text()[-8000:], flush=True)
            try:
                print("Status:", app("status"), flush=True)
                call("herdr-app", "shot", str(root / "failure.png"))
            except Exception:
                pass
            raise
        finally:
            try:
                call("herdr-app", "do", "window.close")
            except Exception:
                pass
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=5)
            # Both HOME and HC_SESSION point only at the disposable test core.
            subprocess.run(
                ["hc", "server", "stop"], env=env, timeout=5,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
            xvfb.terminate()
            xvfb.wait(timeout=5)


if __name__ == "__main__":
    main()
