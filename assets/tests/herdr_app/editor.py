"""Check the App's editor bridge using isolated, headless Neovim servers."""

import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time


SOURCE = Path(__file__).resolve().parents[3] / "dot_scripts/executable_herdr-app-vim"


def main():
    root = Path(tempfile.mkdtemp(prefix="herdr-app-editor-", dir="/tmp/opencode"))
    print(f"Editor sandbox: {root}", flush=True)
    bindir = root / "bin"
    bindir.mkdir()
    log = root / "focus.jsonl"
    app = bindir / "herdr-app"
    app.write_text(
        "#!/usr/bin/env python3\nimport json,os,sys\n"
        "if sys.argv[1:] == ['ls']:\n"
        " print(open(os.environ['APP_LAYOUT']).read())\n"
        "else:\n"
        " with open(os.environ['FOCUS_LOG'], 'a') as log: log.write(json.dumps(sys.argv[1:]) + '\\n')\n"
    )
    app.chmod(0o700)
    env = {**os.environ, "HOME": str(root), "XDG_RUNTIME_DIR": str(root / "runtime"),
           "XDG_CONFIG_HOME": str(root / "config"), "XDG_DATA_HOME": str(root / "data"),
           "XDG_STATE_HOME": str(root / "state"), "XDG_CACHE_HOME": str(root / "cache"),
           "HERDR_APP_HOME": str(root / "app"), "PATH": f"{bindir}:{os.environ['PATH']}",
           "FOCUS_LOG": str(log), "APP_LAYOUT": str(root / "layout.json"),
           "HC_TERMINAL_ID": "git-terminal", "HERDR_ENV": "1", "HERDR_SOCKET_PATH": "/invalid-tui-socket"}
    (root / "runtime").mkdir(mode=0o700)
    servers = []
    layout = {"spaces": [{"id": space, "tabs": []} for space in ("one", "two")]}
    (root / "layout.json").write_text(json.dumps(layout))

    def helper(space, *args, check=True):
        return subprocess.run(["bash", str(SOURCE), *args], env={**env, "HERDR_APP_SPACE_ID": space},
                              cwd=root, text=True, capture_output=True, timeout=10, check=check)

    def evaluate(socket, expression):
        return subprocess.check_output(["nvim", "--server", str(socket), "--remote-expr", expression],
                                       env=env, text=True, timeout=5).strip()

    def start(space, terminal, name):
        before = set((root / "runtime").rglob("*.sock"))
        process = subprocess.Popen(
            ["bash", str(SOURCE), "--start", "--headless", "-u", "NONE", "-i", "NONE"],
            env={**env, "HERDR_APP_SPACE_ID": space, "HC_TERMINAL_ID": terminal}, cwd=root,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        servers.append(process)
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            sockets = set((root / "runtime").rglob("*.sock")) - before
            if sockets and evaluate(next(iter(sockets)), "1") == "1":
                break
            time.sleep(0.05)
        else:
            raise AssertionError(f"Editor for {space}/{terminal} did not start")
        socket, = sockets
        next(item for item in layout["spaces"] if item["id"] == space)["tabs"].append(
            {"name": name, "terminals": [{"terminal": terminal}]})
        (root / "layout.json").write_text(json.dumps(layout))
        return process, socket

    # A lock inherited from an older editor must not restrict new terminals.
    state_dir = root / "runtime/herdr-app-nvim"
    state_dir.mkdir(mode=0o700)
    old_key = hashlib.sha256(f"{env['HERDR_APP_HOME']}\0one\0".encode()).hexdigest()[:24]
    old_lock = (state_dir / f"{old_key}.lock").open("w")
    fcntl.flock(old_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    try:
        sql, sql_socket = start("one", "sql-terminal", "sql")
        other, other_socket = start("one", "other-terminal", "scratch")
        editors = {}
        for space in ("one", "two"):
            process, socket = start(space, f"editor-{space}", "nvim")
            editors[space] = (process, socket)
            assert helper(space, "--ping").returncode == 0
            file = root / f"{space} space's file.txt"
            file.write_text("first\nsecond\nthird\n")
            helper(space, "--line", "3", str(file))
            actual = evaluate(socket, "expand('%:p')")
            assert actual == str(file), (actual, str(file))
            assert evaluate(socket, "line('.')") == "3"
            assert process.poll() is None
        assert sql.poll() is None and other.poll() is None
        assert evaluate(sql_socket, "expand('%:p')") == ""
        assert evaluate(other_socket, "expand('%:p')") == ""
        editors["one"][0].terminate()
        editors["one"][0].wait(timeout=5)
        layout["spaces"][0]["tabs"] = [tab for tab in layout["spaces"][0]["tabs"] if tab["name"] != "nvim"]
        (root / "layout.json").write_text(json.dumps(layout))
        assert helper("one", "--ping", check=False).returncode != 0
        replacement, replacement_socket = start("one", "replacement-terminal", "nvim")
        assert replacement_socket != editors["one"][1]
        helper("one", "--line", "2", str(root / "one space's file.txt"))
        assert evaluate(replacement_socket, "line('.')") == "2"
        assert sql.poll() is None and other.poll() is None and replacement.poll() is None
        calls = [json.loads(line) for line in log.read_text().splitlines()]
        assert calls == [["do", f"pbogut-tabs.nvim@{space}"] for space in ("one", "two", "one") for _ in range(2)], calls
        print("PASS: concurrent editors in one space, named-tab routing, quoted paths, line numbers, and reopening while other editors and an old lock remain.", flush=True)
    finally:
        old_lock.close()
        for process in servers:
            process.terminate()
            process.wait(timeout=5)


if __name__ == "__main__":
    main()
