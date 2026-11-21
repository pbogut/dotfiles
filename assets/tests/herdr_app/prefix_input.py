"""Measure double-Ctrl+G receipt in an isolated App, including negotiated key modes."""

import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import time

SOURCE = Path(__file__).resolve().parents[3] / "dot_config/herdr-app"


def main():
    root = Path(tempfile.mkdtemp(prefix="herdr-prefix-input-", dir="/tmp/opencode"))
    print(f"Prefix input sandbox: {root}", flush=True)
    env = {k: os.environ[k] for k in ("PATH", "LANG", "USER", "LOGNAME", "TERM") if k in os.environ}
    for key in ("HOME", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME", "XDG_RUNTIME_DIR"):
        directory = root / key
        directory.mkdir(mode=0o700)
        env[key] = str(directory)
    env.update(HERDR_APP_HOME=str(root / "app"), HC_SESSION="prefix-input",
               HERDR_TELEMETRY="0", SHELL="/bin/sh", MANGOHUD="0")
    remote = dict(env)
    for key in ("HOME", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME", "XDG_RUNTIME_DIR"):
        directory = root / "remote" / key
        directory.mkdir(parents=True, mode=0o700)
        remote[key] = str(directory)
    remote["HC_SESSION"] = "remote"
    shutil.copytree(SOURCE, root / "app")
    settings = json.loads((root / "app/settings.json").read_text())
    settings.update(core=shutil.which("hc"), telemetry=False, sounds={"enabled": False})
    (root / "app/settings.json").write_text(json.dumps(settings))
    (root / "app/shared.json").write_text(json.dumps({"frame.welcomed": "skipped"}))
    xvfb = subprocess.Popen(["Xvfb", "-displayfd", "1", "-screen", "0", "1280x800x24", "-nolisten", "tcp"],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    env["DISPLAY"] = ":" + xvfb.stdout.readline().strip()

    def call(*args):
        result = subprocess.run(args, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=15)
        if result.returncode:
            raise RuntimeError(result.stdout)
        return result.stdout.strip()

    def app(*args):
        return json.loads(call("herdr-app", *args))

    def wait(check, message, timeout=5):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if check():
                return
            time.sleep(0.005)
        raise AssertionError(message)

    def key(*keys, delay=20):
        call("xdotool", "key", "--clearmodifiers", "--delay", str(delay), *keys)

    with (root / "app.log").open("w") as log:
        process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
        try:
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            call("xdotool", "windowfocus", window)
            app("do", "layout.switch", "--name", "pbogut")
            via = shlex.join(["env", "-i", *[f"{k}={v}" for k, v in remote.items()], "/bin/sh", "-c"])
            call("hc", "machine", "add", "--via", via, "--name", "fixture", "--session", "remote")
            modes = [
                ("legacy", "", b"\x07"),
                ("kitty", "\x1b[>1u", b"\x1b[103;5u"),
                ("kitty-all", "\x1b[>31u", b"\x1b[103;5u"),
                ("modify", "\x1b[>4;2m", b"\x1b[27;5;103~"),
                ("win32", "\x1b[?9001h", b"\x07"),
            ]
            for machine, name, mode, expected in [(m, *case) for m in ("", "fixture") for case in modes]:
                if name == "legacy":
                    app("do", "space.new", "--name", machine or "local", "--folder", str(root), "--machine", machine)
                label = f"{machine or 'local'}-{name}"
                output = root / f"{label}.jsonl"
                program = (
                    "import json,os,signal,time,tty\n"
                    "tty.setraw(0)\n"
                    f"f = open({str(output)!r}, 'w', buffering=1)\n"
                    "def record(kind, value): f.write(json.dumps([kind,time.monotonic_ns(),value])+'\\n')\n"
                    "signal.signal(signal.SIGWINCH, lambda *_: record('resize', list(os.get_terminal_size())))\n"
                    f"print({mode!r} + 'RAW-READY', flush=True)\n"
                    "while True:\n"
                    " data = os.read(0,4096)\n"
                    " record('input', data.hex())\n"
                )
                created = app("do", "tab.new", "--name", name, "--argv",
                              json.dumps([sys.executable, "-u", "-c", program]))
                terminal = created["terminal"]
                assert terminal.startswith("fixture/") == bool(machine), terminal
                wait(lambda: "RAW-READY" in call("hc", "read", terminal, "--lines", "0"), "Raw fixture ready")

                def records():
                    return [json.loads(line) for line in output.read_text().splitlines() if line.endswith("]")]

                def received(start):
                    return b"".join(bytes.fromhex(row[2]) for row in records()[start:] if row[0] == "input")

                key("a")
                wait(lambda: any(row[0] == "input" for row in records()), "Typing reaches the fixture")
                latencies = []
                focus = app("status")["focused_pane"]
                for _ in range(5):
                    start = len(records())
                    key("ctrl+g")
                    wait(lambda: "pbogut-keys" in app("status")["overlays"], "Prefix opens")
                    pressed = time.monotonic_ns()
                    key("ctrl+g", delay=0)
                    wait(lambda: received(start) == expected, "Ctrl+G arrives promptly", timeout=0.5)
                    receipt = next(row[1] for row in records()[start:] if row[0] == "input")
                    latencies.append((receipt - pressed) / 1e6)
                    assert latencies[-1] < 250, latencies
                    assert not any(row[0] == "resize" for row in records()[start:])
                start = len(records())
                key(*(["ctrl+g", "ctrl+g"] * 8), delay=10)
                wait(lambda: received(start) == expected * 8, "Rapid pairs deliver exactly eight keys", timeout=0.5)
                assert not any(row[0] == "resize" for row in records()[start:])
                assert not app("status")["overlays"], app("status")
                key("ctrl+g", "Escape")
                assert not app("status")["overlays"]
                assert app("status")["focused_pane"] == focus
                if name == "legacy" and not machine:
                    start = len(records())
                    call("xdotool", "keydown", "Alt_L", "keydown", "o")
                    time.sleep(1.0)  # X11 auto-repeat must not count as a second tap.
                    call("xdotool", "keyup", "o", "keyup", "Alt_L")
                    assert app("status")["overlays"] == ["pbogut-keys"], "Holding O must leave the hints open"
                    key("Escape")
                    key("alt+o", "z", "Escape")
                    wait(lambda: not app("status")["overlays"], "Escape dismisses space hints")
                    call("xdotool", "keydown", "Alt_L", "key", "o", "key", "o", "keyup", "Alt_L")
                    wait(lambda: "pbogut-spaces" in app("status")["overlays"], "Held Alt and two taps open search")
                    key("z", "Escape")
                    for shortcut in ("alt+o", "alt+i"):
                        key(shortcut, shortcut, shortcut, delay=20)
                        wait(lambda: not app("status")["overlays"], "Third tap leaves only the terminal")
                    key("alt+o", "alt+o", "alt+i")
                    wait(lambda: app("status")["overlays"] == ["pbogut-keys"], "Agent hints replace space search")
                    key("alt+i")
                    wait(lambda: app("status")["overlays"] == ["pbogut-agents"], "Agent search replaces the hints")
                    key("Escape")
                    wait(lambda: not app("status")["overlays"], "One Escape closes the picker")
                    key("alt+o", "ctrl+shift+k")
                    wait(lambda: app("status")["overlays"] == ["pbogut-picker"], "Losing focus closes hint mode")
                    key("Escape")
                    key("alt+o", "f")
                    key("b")
                    wait(lambda: received(start) == b"b", "Only typing after hints reaches the terminal")
                start = len(records())
                key("b")
                typed = b"\x1b[98;;98u" if name == "kitty-all" else b"b"
                wait(lambda: received(start) == typed, "Normal typing resumes after passthrough")
                if name == "win32":
                    for width, height in [(720, 600), (1280, 800)]:
                        start = len(records())
                        call("xdotool", "windowsize", "--sync", window, str(width), str(height))
                        wait(lambda: any(row[0] == "resize" for row in records()[start:]), "App still owns resize")
                        size = json.loads(call("hc", "get", terminal))
                        start = len(records())
                        key("ctrl+g", "ctrl+g")
                        wait(lambda: received(start) == expected, "Passthrough after resize")
                        assert not any(row[0] == "resize" for row in records()[start:])
                        after = json.loads(call("hc", "get", terminal))
                        assert (size["cols"], size["rows"]) == (after["cols"], after["rows"])
                print(f"{label}: second press to receipt {min(latencies):.1f}-{max(latencies):.1f} ms; rapid pairs passed.", flush=True)
            assert not app("status")["errors"], app("status")
        except Exception:
            print((root / "app.log").read_text()[-6000:], flush=True)
            print("Status:", app("status"), flush=True)
            raise
        finally:
            process.terminate()
            process.wait(timeout=5)
            for core_env in (env, remote):
                subprocess.run(["hc", "server", "stop"], env=core_env, timeout=10,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            xvfb.terminate()
            xvfb.wait(timeout=5)


if __name__ == "__main__":
    main()
