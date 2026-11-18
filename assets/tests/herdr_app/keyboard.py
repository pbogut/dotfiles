"""Exercise Herdr shortcuts in a disposable X11 window and core session."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

from PIL import Image, ImageColor, ImageGrab


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

    def clipboard():
        return subprocess.check_output(
            ["xclip", "-selection", "clipboard", "-o"], env=env, text=True, timeout=15,
        )

    def wait_for(check, description):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            if check():
                return
            time.sleep(0.05)
        raise AssertionError(description)

    def key(*keys):
        call("xdotool", "key", "--clearmodifiers", "--delay", "80", *keys)

    def cursor_motion(keys):
        color = ImageColor.getrgb(json.loads((SOURCE / "themes/tokyo-night.json").read_text())["selection"])
        largest = 0
        frames = 0
        with subprocess.Popen(
            ["xdotool", "key", "--clearmodifiers", "--delay", "30", *keys], env=env,
        ) as motion:
            deadline = time.monotonic() + 10
            while motion.poll() is None and time.monotonic() < deadline:
                image = ImageGrab.grab(bbox=(269, 0, 1280, 694), xdisplay=env["DISPLAY"]).convert("RGB")
                pixels = dict((rgb, count) for count, rgb in image.getcolors(image.width * image.height))
                selected = pixels.get(color, 0)
                frames += 1
                if selected > largest:
                    largest = selected
                    image.save(root / "cursor-motion.png")
            motion.wait(timeout=2)
        assert motion.returncode == 0
        assert frames > 5 and 0 < largest < 600, (frames, largest, "Cursor movement must never paint a selection range")
        print(f"Cursor motion: {frames} frames, at most {largest} highlighted pixels.", flush=True)

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

    def bar_snapshot(name, width, height):
        colors = json.loads((SOURCE / "themes/tokyo-night.json").read_text())
        top = height - 70 - 36
        expected = [
            ((271, top + 2), colors["colors"]["popover"]),
            ((width - 2, top + 2), colors["colors"]["popover"]),
            ((width - 2, top - 2), colors["background"]),
            ((266, top + 2), colors["colors"]["chrome"]),
        ]

        def matches():
            path = root / f"{name}.png"
            call("herdr-app", "shot", str(path))
            with Image.open(path) as image:
                image = image.convert("RGB")
                return image.size == (width, height) and all(
                    image.getpixel(point) == ImageColor.getrgb(color)
                    for point, color in expected
                )

        wait_for(matches, f"{name}: bar follows window dimensions above tabs, excluding sidebar")

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
            bar_snapshot("prefix", 1280, 800)
            call("xdotool", "windowsize", "--sync", window, "720", "600")
            bar_snapshot("prefix-resized", 720, 600)
            call("xdotool", "windowsize", "--sync", window, "1280", "800")
            bar_snapshot("prefix-restored", 1280, 800)
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
            key("ctrl+g", "g", "h", "p", "n", "y", "ctrl+y", "ctrl+k", "shift+s", "ctrl+shift+d", "1")
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
            key("Home", "v", "l", "l")
            bar_snapshot("copy", 1280, 800)
            call("xdotool", "windowsize", "--sync", window, "720", "600")
            bar_snapshot("copy-resized", 720, 600)
            key("l")
            call("xdotool", "windowsize", "--sync", window, "1280", "800")
            bar_snapshot("copy-restored", 1280, 800)
            key("l")
            key("y")
            wait_for(lambda: not app("status")["overlays"], "Y copies and leaves copy mode")
            assert clipboard() == "abcde", "Resize must preserve copy selection and selection mode"
            key("alt+Escape", "Escape")
            wait_for(lambda: not app("status")["overlays"], "Escape leaves copy mode")
            key("alt+Escape", "alt+Escape")
            wait_for(lambda: not app("status")["overlays"], "Alt+Esc toggles copy mode off")
            key("ctrl+g", "alt+Escape")
            wait_for(lambda: app("status")["overlays"] == ["pbogut-copy"], "Copy mode replaces the prefix overlay")
            key("ctrl+g")
            wait_for(lambda: app("status")["overlays"] == ["pbogut-keys"], "Prefix mode replaces copy mode")
            key("Escape")
            key("alt+Escape")
            wait_for(lambda: app("status")["overlays"] == ["pbogut-copy"], "Copy mode reopens after replacement")
            call("xdotool", "mousemove", "--window", window, "400", "200", "click", "1")
            wait_for(lambda: not app("status")["overlays"], "Clicking the terminal closes copy mode")

            # Start mid-line; unequal lengths and indentation expose partial-line copies.
            lines = ["first line", "  second line is longer", "    current line", "fourth", "  fifth line"]
            screen = "\033[2J\033[3J\033[H" + "\r\n".join(lines) + "\033[3;9H"
            line_copy = app("do", "tab.new", "--name", "line-copy-test", "--argv", json.dumps([
                "python3", "-u", "-c", f"import sys; sys.stdout.write({screen!r}); sys.stdout.flush(); input()",
            ]))
            terminal = line_copy["terminal"]
            wait_for(lambda: "fifth line" in call("hc", "read", terminal, "--lines", "0"), "Line-copy fixture ready")
            wait_for(lambda: terminal_ready(terminal), "Line-copy terminal available")
            key("alt+Escape")
            wait_for(lambda: "pbogut-copy" in app("status")["overlays"], "Cursor mode opens")
            cursor_motion(["j", "k"] * 20 + ["h", "l", "0", "dollar", "Home", "shift+g", "ctrl+b", "ctrl+f"] * 3)
            key("Escape")
            for delay in (80, 0):
                cases = [(["shift+v", *moves], first, last) for moves, first, last in [
                    ([], 2, 2), (["k"], 1, 2), (["j"], 2, 3),
                    (["k", "j"], 2, 2), (["j", "k"], 2, 2),
                    (["j", "k", "k"], 1, 2), (["k", "j", "j"], 2, 3),
                    (["k", "k", "j"], 1, 2), (["k", "k", "k"], 0, 2),
                    (["j", "j"], 2, 4), (["h", "l", "0", "dollar"], 2, 2),
                    (["g", "g"], 0, 2), (["ctrl+b"], 0, 2), (["ctrl+f", "ctrl+b"], 0, 2),
                ]] + [
                    (["k", "shift+v"], 1, 1),
                    (["k", "shift+v", "j"], 1, 2),
                    (["j", "shift+v", "k", "k"], 1, 3),
                    (["h", "k", "shift+v", "k"], 0, 1),
                    (["v", "k", "shift+v", "j"], 1, 2),
                    (["shift+v", "k", "v", "j", "shift+v"], 2, 2),
                ]
                for keys, first, last in cases:
                    key("alt+Escape")
                    wait_for(lambda: "pbogut-copy" in app("status")["overlays"], "Line-copy mode opens")
                    call("xdotool", "key", "--clearmodifiers", "--delay", str(delay), *keys, "y")
                    wait_for(lambda: not app("status")["overlays"], "Line-copy mode closes")
                    assert clipboard() == "\n".join(lines[first:last + 1]), (delay, keys, repr(clipboard()))

            history = [f"{i:03d} history line" for i in range(80)]
            screen = "\033[2J\033[3J\033[H" + "\r\n".join(history)
            terminal = app("do", "tab.new", "--name", "cursor-history-test", "--argv", json.dumps([
                "python3", "-u", "-c", f"import sys; sys.stdout.write({screen!r}); sys.stdout.flush(); input()",
            ]))["terminal"]
            wait_for(lambda: history[-1] in call("hc", "read", terminal, "--lines", "0"), "History fixture ready")
            wait_for(lambda: terminal_ready(terminal), "History terminal available")
            rows = json.loads(call("hc", "get", terminal, "--json"))["rows"]
            key("alt+Escape", "g", "g")
            cursor_motion(["ctrl+f", "ctrl+b", "j", "k"] * 8)
            key("Escape")
            for keys, row in [
                (["g", "g"], 0),
                (["g", "g", "ctrl+f"], rows),
                (["g", "g", "ctrl+f", "ctrl+b"], 0),
                (["g", "g", "k", "j"], 1),
            ]:
                key("alt+Escape")
                call("xdotool", "key", "--clearmodifiers", "--delay", "0", *keys, "shift+v", "y")
                wait_for(lambda: not app("status")["overlays"], "History copy closes")
                assert clipboard() == history[row], (keys, repr(clipboard()))

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
            key("alt+Escape", "Escape", "d")
            wait_for(lambda: "BYTE:64" in call("hc", "read", terminal, "--lines", "0"), "Copy cancellation restores typing")
            key("alt+Escape", "alt+Escape", "e")
            wait_for(lambda: "BYTE:65" in call("hc", "read", terminal, "--lines", "0"), "Copy toggle restores typing")
            output = call("hc", "read", terminal, "--lines", "0")
            assert all("BYTE:" + byte not in output for byte in ("07", "1b", "7a")), output
            assert "RESIZE:" not in output, output
            assert not bar_open()

            app("do", "app.zoom_in")
            key("ctrl+g")
            wait_for(bar_open, "Bar opens at the new zoom")
            call("herdr-app", "shot", str(root / "zoomed.png"))
            key("Escape")
            key("alt+Escape")
            wait_for(lambda: "pbogut-copy" in app("status")["overlays"], "Copy mode opens at the new zoom")
            call("herdr-app", "shot", str(root / "copy-zoomed.png"))
            key("Escape")
            app("do", "app.zoom_reset")
            key("alt+t", "ctrl+g")
            wait_for(bar_open, "Bar opens with the sidebar hidden")
            call("herdr-app", "shot", str(root / "no-sidebar.png"))
            key("Escape")

            closing_space = app("status")["space"]
            key("ctrl+g", "x")
            wait_for(lambda: all(space["id"] != closing_space for space in app("ls")["spaces"]),
                     "Prefix+x closes the current project")
            assert not bar_open()
            assert not app("status")["errors"], app("status")
            print("PASS: whole-line copying and rapid reversals, live overlay resizing, c/v/s/x actions, restored typing, and clipboard copy.", flush=True)
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
