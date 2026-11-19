import { appHome, exec, hc, home, notify, openOverlay, panes, readTextFile, run, settings, shared, spaces, terminals } from "herdr";
import { isProject, loadProjectConfig, machinePaths, PROJECT_SPACES } from "./project.js";

const active = () => spaces().find(space => space.active);
const message = body => notify({ title: "Project tasks", body, level: "info" });

async function definition(space) {
  const paths = await machinePaths(space.machine, exec, { home: home(), appHome: appHome() });
  const config = await loadProjectConfig(space.folder, exec, readTextFile, `${paths.appHome}/herdr-project.json`, space.machine);
  return { tasks: config.tasks ?? [], app: paths.appHome };
}

function existing(space, name, starting) {
  const tabs = new Set(space.tabs.map(tab => tab.id));
  const records = new Map(terminals().map(t => [t.address, t.labels]));
  for (const pane of panes()) {
    if (!tabs.has(pane.tab)) continue;
    const labels = records.get(pane.terminal);
    if (labels?.["pbogut.task"] === name || pane.terminal === starting) {
      return { ...pane, finished: ["failed", "success"].includes(labels?.["pbogut.task.state"]) };
    }
  }
}

export default class ProjectTasks {
  constructor() {
    this.busy = new Set();
    this.starting = new Map();
  }

  async handle(command) {
    const space = active();
    if (!isProject(space, shared(PROJECT_SPACES))) { message("Open a project to run its tasks."); return; }
    const picker = command === "tasks";
    const request = picker ? {} : JSON.parse(decodeURIComponent(command.slice(5)));
    if (!picker && request.space !== space.id) return;
    const key = JSON.stringify([space.id, request.name]);
    if (this.busy.has(key)) return;
    this.busy.add(key);
    try {
      const { tasks, app } = await definition(space);
      const current = active();
      if (current?.id !== space.id || !isProject(current, shared(PROJECT_SPACES))) return;
      if (picker) {
        if (!tasks.length) { message("No tasks defined."); return; }
        const size = window.viewport_size(), zoom = settings().zoom;
        const viewport = size.width / zoom;
        // Leave room for the popup frame, title and padding at any zoom.
        const maxRows = Math.max(1, Math.floor((size.height / zoom * 0.85 - 80) / 28));
        const columns = Math.ceil(tasks.length / maxRows);
        const width = Math.min(columns === 1 ? 500 : 300 * columns, viewport - 32);
        if ((width - 32) / columns < 80) {
          message("Too many tasks to display at this size. Enlarge the window or zoom out.");
          return;
        }
        openOverlay({ mod: "pbogut-task-picker", kind: "popup", width, at: { x: (viewport - width) / 2, y: 40 },
          props: { space: space.id, tasks: tasks.map(({ name, hint }) => ({ name, hint })), rowsPerColumn: Math.ceil(tasks.length / columns) } });
        return;
      }
      const task = tasks.find(task => task.name === request.name);
      if (!task) throw new Error(`Task "${request.name}" is no longer configured.`);
      const previous = existing(current, task.name, this.starting.get(key));
      if (previous && !previous.finished && space.machine) {
        // A remote task can finish just before the App receives its label update.
        const result = await hc(["get", previous.terminal, "--json"]);
        if (active()?.id !== space.id || !panes().some(p => p.terminal === previous.terminal && p.pane === previous.pane)) return;
        if (result.code === 0) previous.finished = ["failed", "success"].includes(JSON.parse(result.stdout).labels?.["pbogut.task.state"]);
      }
      if (request.replace !== undefined) {
        if (!previous?.finished || previous.terminal !== request.replace) return;
      } else if (previous) {
        run("pane.focus", { pane: previous.pane });
        if (previous.finished) {
          const target = { space: space.id, name: task.name, replace: previous.terminal };
          openOverlay({ mod: "confirm", kind: "dialog", width: 400, height: 160, props: {
            title: `Run ${task.name} again?`, detail: "Replace the finished task and its output with a fresh run.",
            command: { name: `pbogut-tabs.task@${encodeURIComponent(JSON.stringify(target))}` },
          } });
        }
        return;
      }
      // The CLI returns the exact terminal ID, even before its task labels arrive.
      const options = { space: space.id, folder: space.folder, name: task.name,
        argv: ["exec", "bash", `${app}/mods/pbogut-tabs/task.sh`, task.name, String(task.progress), String(task.close), ...task.command] };
      const result = await exec("env", [`HERDR_APP_HOME=${appHome()}`, "herdr-app", "do", "tab.new", JSON.stringify(options)]);
      if (result.code !== 0) throw new Error(result.stderr.trim() || result.stdout.trim() || "Could not open the task tab.");
      const { terminal } = JSON.parse(result.stdout);
      this.starting.set(key, terminal);
      if (previous && panes().some(p => p.pane === previous.pane && p.terminal === previous.terminal)) {
        run("pane.close", { pane: previous.pane });
      }
    } finally {
      this.busy.delete(key);
    }
  }
}
