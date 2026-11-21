import { spawn } from "node:child_process";
import { pathToFileURL } from "node:url";

const label = "pbogut.tab.launch";
const roles = new Set(["nvim", "git", "dev", "sql", "rest", "docker"]);

export function core(method, params) {
  return new Promise((resolve, reject) => {
    const child = spawn("hc", ["connect"], { stdio: ["pipe", "pipe", "pipe"] });
    let input = "",
      stderr = "",
      finished = false;
    const timer = setTimeout(() => finish(new Error(`Core timed out: ${method}`)), 3000);
    function finish(error, result) {
      if (finished) return;
      finished = true;
      clearTimeout(timer);
      child.kill();
      if (error) reject(error);
      else resolve(result);
    }
    child.on("error", finish);
    child.stdin.on("error", finish);
    child.on("close", (code) => finish(new Error(stderr || `hc connect exited: ${code}`)));
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.stdout.on("data", (chunk) => {
      input += chunk;
      const end = input.indexOf("\n");
      if (end < 0) return;
      try {
        const response = JSON.parse(input.slice(0, end));
        finish(response.error ? new Error(response.error.message) : null, response.result);
      } catch (error) {
        finish(error);
      }
    });
    // Keep stdin open until Core replies.
    child.stdin.write(JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }) + "\n");
  });
}

export async function prepare(terminalID, space, role, folder, appHome, argv, rpc = core) {
  if (!terminalID || !space || !roles.has(role) || !argv.length || !argv[0]) {
    throw new Error("Expected a named tab and its launch command");
  }
  const terminal = await rpc("terminal.get", { terminal: terminalID });
  if (
    terminal.state !== "live" ||
    terminal.labels["herdr.space"] !== space ||
    !terminal.labels["herdr.tab"]
  ) {
    throw new Error("The tab must run in its Herdr App space");
  }
  const launch = {
    space,
    tab: terminal.labels["herdr.tab"],
    role,
    folder,
    appHome,
    argv,
    pid: terminal.pid,
  };
  await rpc("terminal.label", {
    terminal: terminalID,
    labels: { [label]: JSON.stringify(launch) },
  });
}

export async function recovery(terminalID, shellPID, rpc = core) {
  if (!terminalID) return;
  const terminal = await rpc("terminal.get", { terminal: terminalID });
  const saved = terminal.labels[label];
  if (!saved) return;
  const launch = JSON.parse(saved);
  // Only a replacement root shell may recover, never a nested or original shell.
  if (
    !roles.has(launch.role) ||
    terminal.state !== "live" ||
    String(terminal.pid) !== shellPID ||
    !launch.pid ||
    String(launch.pid) === shellPID ||
    launch.space !== terminal.labels["herdr.space"] ||
    launch.tab !== terminal.labels["herdr.tab"]
  )
    return;
  const layout = await rpc("doc.get", { name: "herdr-app" });
  const tab = layout.value?.spaces
    ?.find((space) => space.id === launch.space)
    ?.tabs?.find((tab) => tab.id === launch.tab);
  if (tab?.name !== launch.role) return;
  return launch;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const [action, first, ...args] = process.argv.slice(2);
    if (action === "prepare") {
      await prepare(
        process.env.HC_TERMINAL_ID,
        process.env.HERDR_APP_SPACE_ID,
        first,
        process.cwd(),
        process.env.HERDR_APP_HOME,
        args,
      );
    } else if (action === "recover") {
      const launch = await recovery(process.env.HC_TERMINAL_ID, first);
      // End with the role so command substitution cannot trim a command argument.
      if (launch)
        process.stdout.write(
          [launch.folder, launch.appHome, launch.space, ...launch.argv, launch.role].join("\0"),
        );
    } else throw new Error("Expected prepare or recover");
  } catch (error) {
    console.error(`Tab restoration: ${error.message}`);
    process.exitCode = 1;
  }
}
