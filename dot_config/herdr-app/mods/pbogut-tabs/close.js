import { appHome, exec, hc, home, notify, openOverlay, panes, readTextFile, run, shared, spaces, terminals } from "herdr";
import { PROJECT_SPACES, isProject, loadProjectConfig, machinePaths } from "./project.js";

export default class ProjectClose {
  constructor() {
    this.jobs = new Map();
    this.serial = 0;
  }

  busy(space) { return this.jobs.has(space); }

  hook(space, kind, state) {
    for (const pane of panes()) {
      const tab = space.tabs.find(tab => tab.id === pane.tab);
      if (!tab) continue;
      const terminal = terminals().find(terminal => terminal.address === pane.terminal);
      if (terminal?.labels?.[`pbogut.${kind}`] && terminal.labels[`pbogut.${kind}.state`] === state) {
        return { tab, terminal };
      }
    }
  }

  focus(job, space) {
    if (job?.tab && space.active && space.tabs.some(tab => tab.id === job.tab)) run("tab.select", { id: job.tab });
  }

  close(space, setupPending, cx, confirmed = false) {
    if (!isProject(space, shared(PROJECT_SPACES))) {
      run("space.close", { id: space.id });
      return;
    }
    const previous = this.jobs.get(space.id);
    if (previous) { this.focus(previous, space); return; }
    const setup = this.hook(space, "setup", "running");
    if (setupPending || setup) {
      this.focus({ tab: setup?.tab.id }, space);
      notify({ title: "Project setup is running",
        body: "Finish or close the setup tab, then choose Close project.", level: "info" });
      return;
    }
    const job = { space: space.id, token: `${space.id}:${Date.now()}:${++this.serial}` };
    this.jobs.set(space.id, job);
    const running = this.hook(space, "teardown", "running");
    if (running) {
      job.token = running.terminal.labels["pbogut.teardown"];
      job.tab = running.tab.id;
      job.terminal = running.terminal.address;
      this.focus(job, space);
      return;
    }
    cx.spawn(async (cx) => {
      try {
        const paths = await machinePaths(space.machine, exec, { home: home(), appHome: appHome() });
        const config = await loadProjectConfig(space.folder, exec, readTextFile,
          `${paths.appHome}/herdr-project.json`, space.machine);
        if (this.jobs.get(space.id) !== job) return;
        const current = spaces().find(candidate => candidate.id === space.id);
        if (!current) { this.jobs.delete(space.id); return; }
        if (!confirmed) {
          openOverlay({ mod: "confirm", kind: "dialog", width: 380, height: config.teardown ? 170 : 150, props: {
            title: "Close project?",
            detail: config.teardown ? "The configured teardown will run before the project closes." : "",
            command: { name: `pbogut-tabs.close-project@${space.id}@confirmed` },
          } });
          this.jobs.delete(space.id);
          return;
        }
        if (!config.teardown) { this.finish(job, true, cx); return; }
        job.before = new Set(current.tabs.map(tab => tab.id));
        job.argv = ["exec", "bash", `${paths.appHome}/mods/pbogut-tabs/teardown.sh`,
          config.teardown.directory, config.teardown.script, job.token];
        // Keep a terminal in the space while its other tabs close, then start the hook.
        run("tab.new", { name: "teardown", space: space.id, folder: space.folder || paths.home, focus: false,
          argv: ["exec", "bash", "--noprofile", "--norc", "-i"] });
        cx.timer.after(15000, (cx) => {
          if (this.jobs.get(space.id) === job && !job.tab && !job.closing) {
            this.finish(job, false, cx, "The teardown terminal did not appear.");
          }
        });
        cx.notify();
      } catch (error) {
        this.finish(job, false, cx, String(error.message ?? error));
      }
    });
  }

  finish(job, success, cx, detail = "See the teardown tab. Choose Close project again to retry.") {
    if (this.jobs.get(job.space) !== job) return;
    const space = spaces().find(space => space.id === job.space);
    if (!space) { this.jobs.delete(job.space); return; }
    if (success) {
      try {
        job.closing = true;
        run("space.close", { id: job.space, confirmed: true });
        cx.timer.after(15000, (cx) => {
          if (this.jobs.get(job.space) === job) this.finish(job, false, cx, "The space did not close. Try Close project again.");
        });
        return;
      } catch (error) {
        detail = String(error.message ?? error);
      }
    }
    this.jobs.delete(job.space);
    notify({ title: "Could not close project", body: `${space.folder}\n${detail}`, level: "error" });
  }

  update(cx) {
    for (const job of this.jobs.values()) {
      const space = spaces().find(space => space.id === job.space);
      if (!space) { this.jobs.delete(job.space); continue; }
      if (job.closing) continue;
      const terminal = terminals().find(terminal => terminal.labels?.["pbogut.teardown"] === job.token);
      if (terminal) job.terminal = terminal.address;
      const state = terminal?.labels?.["pbogut.teardown.state"];
      if (state === "success" || state === "failed") {
        this.finish(job, state === "success", cx);
        continue;
      }
      if (!job.tab && job.before) {
        const tab = space.tabs.find(tab => !job.before.has(tab.id) && tab.named && tab.name === "teardown");
        if (tab) { job.tab = tab.id; this.focus(job, space); }
      }
      // Fast scripts can exit before their labels reach the App's live terminal list.
      job.terminal ??= panes().find(pane => pane.tab === job.tab)?.terminal;
      if (job.tab && !space.tabs.some(tab => tab.id === job.tab) && !job.checking) {
        job.checking = true;
        cx.spawn(async (cx) => {
          try {
            // Read once after a disappearing tab so a late success event is not mistaken for cancellation.
            const result = job.terminal ? await hc(["get", job.terminal, "--json"]) : null;
            const success = result?.code === 0 &&
              JSON.parse(result.stdout).labels?.["pbogut.teardown.state"] === "success";
            this.finish(job, success, cx, "Teardown was interrupted. Choose Close project to retry.");
          } catch (error) {
            this.finish(job, false, cx, String(error.message ?? error));
          }
        });
      }
      if (job.argv && job.terminal && !job.started && !job.checking) {
        try {
          if (!job.siblings) {
            job.siblings = space.tabs.filter(tab => tab.id !== job.tab).map(tab => tab.id);
            for (const id of job.siblings) run("tab.close", { id });
          }
          if (space.tabs.some(tab => job.siblings.includes(tab.id))) continue;
          job.started = true;
          cx.spawn(async (cx) => {
            try {
              const command = job.argv.map(arg => `'${arg.replaceAll("'", "'\\''")}'`).join(" ");
              const result = await hc(["send", job.terminal, command]);
              if (result.code !== 0) throw new Error(result.stderr.trim() || "Could not start teardown.");
            } catch (error) {
              this.finish(job, false, cx, String(error.message ?? error));
            }
          });
        } catch (error) {
          this.finish(job, false, cx, String(error.message ?? error));
        }
      }
    }
  }
}
