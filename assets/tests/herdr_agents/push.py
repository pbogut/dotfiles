"""Check native app notifications and the push socket in a disposable X11 session."""

import json
import os
import queue
import shutil
import socket
import subprocess
import threading
import time
from pathlib import Path
import tempfile


SOURCE = Path(__file__).resolve().parents[3] / "dot_config/herdr-app"


def main():
    root = Path(tempfile.mkdtemp(prefix="ha-push-", dir="/tmp/opencode"))
    print(f"Sandbox: {root}", flush=True)
    env = {
        key: value for key, value in os.environ.items()
        if not key.startswith(("HC_", "HERDR_"))
        and key not in ("WAYLAND_DISPLAY", "DBUS_SESSION_BUS_ADDRESS")
    }
    for key, name in [
        ("HOME", "home"), ("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
        ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "run"),
    ]:
        directory = root / name
        directory.mkdir(mode=0o700)
        env[key] = str(directory)
    env.update(HERDR_APP_HOME=str(root / "app"), HC_SESSION="push", SHELL="/bin/sh",
               HERDR_TELEMETRY="0", MANGOHUD="0")
    shutil.copytree(SOURCE / "mods/pbogut-agent-status", root / "app/mods/pbogut-agent-status")
    (root / "app/settings.json").write_text(json.dumps({
        "core": shutil.which("hc"), "telemetry": False, "sounds": {"enabled": False},
    }))
    (root / "app/shared.json").write_text(json.dumps({"frame.welcomed": "skipped"}))
    listener = socket.socket()
    listener.bind(("127.0.0.1", 0))
    listener.listen()
    port = listener.getsockname()[1]
    layout = {
        "id": "root", "type": "column",
        "children": [
            {"id": "main", "type": "block", "content": {"tab": "active"}},
            {"id": "push", "type": "block", "size": {"px": 0}, "min": 0,
             "content": {"mod": "pbogut-agent-status", "props": {"port": port}}},
        ],
    }
    (root / "app/layouts").mkdir()
    (root / "app/layouts/push.json").write_text(json.dumps(layout))
    messages = queue.Queue()
    connections = []

    def receive():
        while True:
            try:
                client, _ = listener.accept()
            except OSError:
                return
            connections.append(client)
            messages.put(("connected", len(connections)))
            try:
                with client, client.makefile("rb") as stream:
                    for line in stream:
                        messages.put(("snapshot", json.loads(line)))
            except OSError:
                pass
            messages.put(("closed", None))

    threading.Thread(target=receive, daemon=True).start()

    def wait_for(predicate, timeout=10):
        deadline = time.monotonic() + timeout
        while True:
            event, value = messages.get(timeout=max(0, deadline - time.monotonic()))
            if predicate(event, value):
                return value

    def state(address, expected, focused=None):
        return wait_for(lambda event, value: event == "snapshot" and any(
            item["address"] == address and item["status"] == expected
            and (focused is None or item["focused"] == focused)
            for item in value["agents"]
        ))

    def call(*args):
        return subprocess.check_output(args, env=env, text=True, stderr=subprocess.STDOUT, timeout=15).strip()

    def app(*args):
        return json.loads(call("herdr-app", *args))

    writers = []

    def agent(name):
        fifo = root / name
        os.mkfifo(fifo)
        code = (
            "import sys\n"
            "with open(sys.argv[1]) as stream:\n"
            " for state in stream:\n"
            "  print(chr(27)+']7501;state='+state.strip()+':app=widget-test'+chr(27)+chr(92),end='',flush=True)\n"
        )
        created = app("do", "tab.new", "--name", name, "--argv", json.dumps([
            "exec", "python3", "-u", "-c", code, str(fifo),
        ]))
        deadline = time.monotonic() + 5
        while True:
            try:
                descriptor = os.open(fifo, os.O_WRONLY | os.O_NONBLOCK)
                break
            except OSError:
                if time.monotonic() > deadline:
                    raise
                time.sleep(0.02)
        writer = os.fdopen(descriptor, "w", buffering=1)
        writers.append(writer)
        return created["terminal"], writer

    xvfb = subprocess.Popen(
        ["Xvfb", "-displayfd", "1", "-screen", "0", "1000x700x24", "-nolisten", "tcp"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
    )
    env["DISPLAY"] = ":" + xvfb.stdout.readline().strip()
    with (root / "app.log").open("w") as log:
        process = subprocess.Popen(["herdr-app"], env=env, stdout=log, stderr=log)
        try:
            window = call("xdotool", "search", "--sync", "--pid", str(process.pid)).splitlines()[0]
            call("xdotool", "windowfocus", window)
            app("do", "layout.switch", "--name", "push")
            wait_for(lambda event, value: event == "snapshot" and value == {"version": 1, "agents": []})
            app("do", "space.new", "--name", "push-test", "--folder", str(root / "home"))
            first, writer = agent("first")
            writer.write("idle\n")
            state(first, "idle", True)
            second, other_writer = agent("second")
            other_writer.write("idle\n")
            state(second, "idle", True)
            writer.write("working\n")
            state(first, "working", False)
            writer.write("idle\n")
            state(first, "done", False)
            app("do", "agent.focus", "--terminal", first)
            state(first, "idle", True)
            app("do", "agent.focus", "--terminal", second)
            state(second, "idle", True)
            # Longer than the native net module's 30-second read timeout.
            try:
                unexpected = messages.get(timeout=32)
            except queue.Empty:
                pass
            else:
                raise AssertionError(("Idle connection sent traffic", unexpected))
            assert len(connections) == 1
            print("PASS: native Done/focus updates, 32 seconds idle with no traffic or reconnect.", flush=True)
            connections[-1].shutdown(socket.SHUT_RDWR)
            wait_for(lambda event, value: event == "closed")
            wait_for(lambda event, value: event == "connected" and value == 2)
            snapshot = state(second, "idle", True)
            assert len(snapshot["agents"]) == 2
            app("do", "layout.switch", "--name", "main")
            wait_for(lambda event, value: event == "closed")
            app("do", "layout.switch", "--name", "push")
            wait_for(lambda event, value: event == "connected" and value == 3)
            state(second, "idle", True)
            assert not app("status")["errors"], app("status")
            app("do", "window.close")
            process.wait(timeout=5)
            wait_for(lambda event, value: event == "closed")
            print("PASS: reconnect sends current state; mod unload and window close close the socket.", flush=True)
        except Exception:
            print((root / "app.log").read_text()[-6000:], flush=True)
            try:
                print("App:", app("ls"), flush=True)
                print("Core:", call("hc", "ls", "--json"), flush=True)
            except Exception:
                pass
            raise
        finally:
            for writer in writers:
                writer.close()
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=5)
            subprocess.run(["hc", "server", "stop"], env=env, timeout=5,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            for client in connections:
                client.close()
            listener.close()
            xvfb.terminate()
            xvfb.wait(timeout=5)


if __name__ == "__main__":
    main()
