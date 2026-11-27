import { View, div } from "gpui-kit";
import {
  appHome,
  checking,
  exec,
  home,
  nextCommand,
  notify,
  panes,
  readTextFile,
  run,
  setShared,
  shared,
  spaces,
  terminals,
} from "herdr";
import { commandFor, compareTabs, roleOf } from "./roles.js";
import {
  PROJECT_SPACES,
  isProject,
  folderKey,
  loadProjectConfig,
  machinePaths,
} from "./project.js";
import ProjectClose from "./close.js";
import ProjectTasks from "./tasks.js";

export default class NamedTabs extends View {
  init(_props, cx) {
    this.queue = [];
    this.setups = new Map();
    this.setupSerial = 0;
    this.closer = new ProjectClose();
    this.tasks = new ProjectTasks();
    if (checking()) return;
    this.syncTabs();
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command === "last" || command === "last-oc") {
          const recent = this.syncTabs();
          if (!recent) continue;
          let id = recent[1];
          if (command === "last-oc") {
            const openCodeTabs = new Set(
              panes().filter((pane) => pane.program?.key === "opencode").map((pane) => pane.tab),
            );
            id = recent.find((id) => openCodeTabs.has(id));
          }
          if (id && id !== recent[0]) run("tab.select", { id });
          continue;
        }
        if (command === "tasks" || command.startsWith("task@")) {
          cx.spawn(async () => {
            try {
              await this.tasks.handle(command);
            } catch (error) {
              notify({
                title: "Could not run project task",
                body: String(error.message ?? error),
                level: "error",
              });
            }
          });
          continue;
        }
        if (command === "reload-project" || command.startsWith("project@")) {
          try {
            const reload = command === "reload-project";
            const project = reload
              ? spaces().find((space) => space.active)
              : JSON.parse(decodeURIComponent(command.slice(8)));
            if (reload || project?.id) {
              if (!isProject(project, shared(PROJECT_SPACES))) {
                if (reload)
                  notify({
                    title: "Could not reload project config",
                    body: "The active space is not a project.",
                    level: "info",
                  });
                continue;
              }
            }
            if (!project?.folder?.startsWith("/")) {
              if (reload)
                notify({
                  title: "Could not reload project config",
                  body: "The active space has no project folder.",
                  level: "error",
                });
              continue;
            }
            if (
              ![this.pending, ...this.queue].some(
                (request) =>
                  request?.project &&
                  (request.project.machine ?? null) === (project.machine ?? null) &&
                  folderKey(request.project.folder) === folderKey(project.folder),
              )
            ) {
              this.queue.push({ project, reload });
            }
            this.drain(cx);
          } catch (error) {
            notify({
              title: "Could not open project",
              body: String(error.message ?? error),
              level: "error",
            });
          }
          continue;
        }
        const [name, target, extra] = command.split("@");
        if (name === "close-project" && (extra === undefined || extra === "confirmed")) {
          const space = spaces().find((space) =>
            target === undefined ? space.active : space.id === target,
          );
          if (space) this.closer.close(space, this.setups.has(space.id), cx, extra === "confirmed");
          continue;
        }
        const role = roleOf(name);
        if (!role || extra !== undefined) continue;
        const space = target === undefined ? spaces().find((space) => space.active)?.id : target;
        if (!space) continue;
        if (
          ![this.pending, ...this.queue].some(
            (request) => !request?.layout && request?.space === space && request.role === role,
          )
        ) {
          this.queue.push({ role, space, explicit: target !== undefined });
        }
        this.drain(cx);
      }
    });
  }

  openProject(request, cx) {
    cx.spawn(async (cx) => {
      const project = request.project;
      if (
        project.id &&
        !spaces().some(
          (space) => space.id === project.id && isProject(space, shared(PROJECT_SPACES)),
        )
      ) {
        this.pending = null;
        this.drain(cx);
        return;
      }
      try {
        request.paths = await machinePaths(project.machine, exec, {
          home: home(),
          appHome: appHome(),
        });
        request.config = await loadProjectConfig(
          project.folder,
          exec,
          readTextFile,
          `${request.paths.appHome}/herdr-project.json`,
          project.machine,
        );
      } catch (error) {
        request.failed = true;
        request.config = { tabs: [] };
        notify({
          title: "Could not load project configuration",
          body: String(error.message ?? error),
          level: "error",
        });
      }
      if (this.pending !== request) return;
      const existing = spaces().find(
        (space) =>
          isProject(space, shared(PROJECT_SPACES)) &&
          (project.id
            ? space.id === project.id
            : (space.machine ?? null) === (project.machine ?? null) &&
              folderKey(space.folder) === folderKey(project.folder)),
      );
      if (existing) {
        if (!request.reload) run("space.select", { id: existing.id });
        if (request.failed) {
          this.pending = null;
          this.drain(cx);
        } else this.projectReady(request, existing, false, cx);
      } else if (project.id) {
        this.pending = null;
        this.drain(cx);
      } else {
        try {
          // run() returns no ID. Use the app's response so another space created
          // in the same directory cannot accidentally receive the project marker.
          const result = await exec("env", [
            `HERDR_APP_HOME=${appHome()}`,
            "herdr-app",
            "do",
            "space.new",
            JSON.stringify({
              name: project.label,
              folder: project.folder,
              machine: project.machine ?? "",
            }),
          ]);
          if (result.code !== 0)
            throw new Error(
              result.stderr?.trim() ||
                result.stdout?.trim() ||
                "Could not create the project space.",
            );
          const { space } = JSON.parse(result.stdout);
          if (typeof space !== "string" || !space)
            throw new Error("Space creation returned no space ID.");
          if (this.pending !== request) return;
          request.created = space;
          this.timeout(request, project.label || project.folder, cx);
          cx.notify();
        } catch (error) {
          this.pending = null;
          notify({
            title: "Could not open project",
            body: String(error.message ?? error),
            level: "error",
          });
          this.drain(cx);
        }
      }
    });
  }

  projectReady(request, space, created, cx) {
    if (this.pending === request) this.pending = null;
    if (created) setShared(PROJECT_SPACES, { ...(shared(PROJECT_SPACES) ?? {}), [space.id]: true });
    if (!isProject(space, shared(PROJECT_SPACES))) {
      this.drain(cx);
      return;
    }
    if (this.closer.busy(space.id)) {
      this.drain(cx);
      return;
    }
    if (!("initial" in request)) request.initial = created ? space.tabs[0]?.id : null;
    if (!request.failed && request.config.setup && !request.setupDone) {
      this.startSetup(request, space, cx);
      this.drain(cx);
      return;
    }
    const { config } = request;
    if (!request.failed)
      run(
        `pbogut-spaces.reload@${encodeURIComponent(
          JSON.stringify({
            folder: space.folder,
            machine: space.machine ?? null,
          }),
        )}`,
      );
    this.sortTabs(space);
    const layout = { initial: config.tabs.length ? request.initial : null };
    this.queue.unshift(
      ...config.tabs.map((role, index) => ({
        space: space.id,
        role,
        layout,
        config,
        paths: request.paths,
        last: index === config.tabs.length - 1,
      })),
    );
    this.drain(cx);
  }

  startSetup(request, space, cx) {
    const previous = this.setups.get(space.id);
    if (previous) {
      if (previous.tab && space.active && !request.reload) run("tab.select", { id: previous.tab });
      return;
    }
    const setup = request.config.setup;
    const job = {
      request,
      space: space.id,
      token: `${space.id}:${Date.now()}:${++this.setupSerial}`,
      previousTab: space.tabs.find((tab) => tab.active)?.id,
    };
    job.args = [
      `${request.paths.appHome}/mods/pbogut-tabs/setup.sh`,
      "check",
      request.paths.appHome,
      setup.directory,
      setup.script,
      job.token,
    ];
    this.setups.set(space.id, job);
    cx.spawn(async (cx) => {
      try {
        const result = await exec("bash", job.args, {
          cwd: space.folder,
          on: space.machine ?? null,
        });
        if (this.setups.get(space.id) !== job) return;
        const current = spaces().find((candidate) => candidate.id === space.id);
        if (!current) {
          this.setups.delete(space.id);
          return;
        }
        if (result.code === 0) {
          this.finishSetup(job, true, cx);
          return;
        }
        if (result.code !== 75)
          throw new Error(result.stderr.trim() || `Setup check exited ${result.code}.`);
        for (const tab of current.tabs) {
          if (!tab.named || tab.name !== "setup" || tab.panes !== 1) continue;
          const pane = panes().find((pane) => pane.tab === tab.id);
          const terminal = terminals().find((terminal) => terminal.address === pane?.terminal);
          const labels = terminal?.labels;
          if (!labels?.["pbogut.setup"]) continue;
          if (labels["pbogut.setup.state"] === "failed") run("tab.close", { id: tab.id });
          else if (labels["pbogut.setup.state"] === "running") {
            job.token = labels["pbogut.setup"];
            job.tab = tab.id;
            job.restart = labels["pbogut.setup.hash"] !== result.stdout.trim();
            if (current.active) run("tab.select", { id: tab.id });
            return;
          }
        }
        job.before = new Set(current.tabs.map((tab) => tab.id));
        run("tab.new", {
          name: "setup",
          space: space.id,
          folder: space.folder,
          focus: false,
          argv: ["exec", "bash", job.args[0], "run", ...job.args.slice(2)],
        });
        cx.timer.after(15000, (cx) => {
          if (this.setups.get(space.id) === job && !job.tab) {
            this.finishSetup(job, false, cx, "The setup terminal did not appear.");
          }
        });
        cx.notify();
      } catch (error) {
        this.finishSetup(job, false, cx, String(error.message ?? error));
      }
    });
  }

  finishSetup(
    job,
    success,
    cx,
    detail = "See the setup tab. Reopen the project or reload its config to retry.",
  ) {
    if (this.setups.get(job.space) !== job) return;
    this.setups.delete(job.space);
    const space = spaces().find((space) => space.id === job.space);
    if (!space) return;
    if (!success) {
      notify({ title: "Project setup failed", body: `${space.folder}\n${detail}`, level: "error" });
      return;
    }
    if (job.restart) {
      this.startSetup(job.request, space, cx);
      return;
    }
    if (space.active && job.focused && space.tabs.some((tab) => tab.id === job.previousTab))
      run("tab.select", { id: job.previousTab });
    job.request.setupDone = true;
    this.projectReady(job.request, space, false, cx);
  }

  updateSetups(cx) {
    for (const job of this.setups.values()) {
      const space = spaces().find((space) => space.id === job.space);
      if (!space) {
        this.setups.delete(job.space);
        continue;
      }
      const setupTab = space.tabs.find((tab) => tab.id === job.tab);
      if (setupTab) job.focused = space.active && setupTab.active;
      const terminal = terminals().find(
        (terminal) => terminal.labels?.["pbogut.setup"] === job.token,
      );
      const state = terminal?.labels?.["pbogut.setup.state"];
      if (state === "success" || state === "failed") {
        this.finishSetup(job, state === "success", cx);
        continue;
      }
      if (!job.tab && job.before) {
        const tab = space.tabs.find(
          (tab) => !job.before.has(tab.id) && tab.named && tab.name === "setup",
        );
        if (tab) {
          job.tab = tab.id;
          if (space.active) run("tab.select", { id: tab.id });
        }
      }
      if (job.tab && !space.tabs.some((tab) => tab.id === job.tab) && !job.checking) {
        job.checking = true;
        cx.spawn(async (cx) => {
          try {
            const result = await exec("bash", job.args, {
              cwd: space.folder,
              on: space.machine ?? null,
            });
            this.finishSetup(
              job,
              result.code === 0,
              cx,
              "Setup was interrupted. Reopen the project to retry.",
            );
          } catch (error) {
            this.finishSetup(job, false, cx, String(error.message ?? error));
          }
        });
      }
    }
  }

  // Read Herdr's selection so clicks, shortcuts and scripted focus all count.
  syncTabs() {
    const previous = this.tabsBySpace;
    this.tabsBySpace = new Map();
    let active;
    for (const space of spaces()) {
      const known = previous?.get(space.id);
      const ids = new Set(space.tabs.map((tab) => tab.id));
      let recent = known?.recent.filter((id) => ids.has(id)) ?? [];
      if (space.active) {
        const current = space.tabs.find((tab) => tab.active)?.id;
        if (current) {
          if (recent[0] !== current) recent = [current, ...recent.filter((id) => id !== current)];
          active = recent;
        }
      }
      this.tabsBySpace.set(space.id, { ids, recent });
      if (space.tabs.some((tab) => !known?.ids.has(tab.id))) this.sortTabs(space);
    }
    return active;
  }

  sortTabs(space) {
    const tabs = [...space.tabs].sort(compareTabs);
    if (tabs.every((tab, index) => tab.id === space.tabs[index].id)) return;
    tabs.forEach((tab, index) => run("tab.move", { id: tab.id, index: index + 1 }));
  }

  complete(request, space, tab) {
    if (request.layout) {
      const initial = space.tabs.find(
        (tab) => tab.id === request.layout.initial && !tab.named && tab.panes === 1,
      );
      if (initial && !request.layout.focused) {
        if (space.active) run("tab.select", { id: tab.id });
        request.layout.focused = true;
      }
      this.closeInitial(request, space);
    } else if (space.active || request.explicit) {
      run("tab.select", { id: tab.id });
    }
  }

  closeInitial(request, space) {
    if (!request.last || !request.layout?.initial || !space) return;
    const initial = space.tabs.find(
      (tab) => tab.id === request.layout.initial && !tab.named && tab.panes === 1,
    );
    const roles = request.config.tabs;
    if (initial && space.tabs.some((tab) => tab.named && roles.includes(roleOf(tab.name)))) {
      run("tab.close", { id: initial.id });
    }
    request.layout.initial = null;
  }

  timeout(request, name, cx) {
    cx.timer.after(15000, (cx) => {
      if (this.pending !== request) return;
      this.pending = null;
      this.closeInitial(
        request,
        spaces().find((space) => space.id === request.space),
      );
      notify({
        title: `Could not create ${name}`,
        body: "It did not appear. Try opening it again.",
        level: "error",
      });
      this.drain(cx);
    });
  }

  loadSettings(request, space, cx) {
    request.loading = true;
    cx.spawn(async (cx) => {
      try {
        const paths = await machinePaths(space.machine, exec, { home: home(), appHome: appHome() });
        if (request.role === "dev" && isProject(space, shared(PROJECT_SPACES))) {
          request.config = await loadProjectConfig(
            space.folder,
            exec,
            readTextFile,
            `${paths.appHome}/herdr-project.json`,
            space.machine,
          );
        }
        request.paths = paths;
      } catch (error) {
        notify({
          title: "Could not load tab configuration",
          body: String(error.message ?? error),
          level: "error",
        });
      }
      if (this.pending !== request) return;
      request.loading = false;
      this.pending = null;
      // Recheck the space and existing tabs after the asynchronous file read.
      if (request.paths) this.queue.unshift(request);
      this.drain(cx);
    });
  }

  drain(cx) {
    while (!this.pending && this.queue.length) {
      const request = this.queue.shift();
      if (request.project) {
        this.pending = request;
        this.openProject(request, cx);
        continue;
      }
      const space = spaces().find((space) => space.id === request.space);
      if (!space) continue;
      const tab = space.tabs.find((tab) => tab.named && roleOf(tab.name) === request.role);
      if (tab) {
        if (tab.name !== request.role) run("tab.rename", { id: tab.id, name: request.role });
        this.complete(request, space, tab);
        continue;
      }
      this.pending = request;
      if (
        !request.paths &&
        (space.machine || (request.role === "dev" && isProject(space, shared(PROJECT_SPACES))))
      ) {
        this.loadSettings(request, space, cx);
        continue;
      }
      const paths = request.paths ?? { appHome: appHome(), home: home() };
      const argv = commandFor(request.role, space, paths.appHome, paths.home, request.config?.dev);
      try {
        run("tab.new", {
          name: request.role,
          space: space.id,
          folder: space.folder || undefined,
          focus: false,
          // Replace the App's keep-open shell so program exit closes the pane.
          argv: argv ? ["exec", ...argv] : undefined,
        });
      } catch (error) {
        this.pending = null;
        this.closeInitial(request, space);
        notify({
          title: `Could not create ${request.role}`,
          body: String(error.message ?? error),
          level: "error",
        });
        continue;
      }
      // Creation talks to the core. Wait for the actual tab in spaces(), not a delay.
      this.timeout(request, request.role, cx);
    }
  }

  render(cx) {
    if (checking()) return div().h(0);
    this.syncTabs();
    this.closer.update(cx);
    this.updateSetups(cx);
    if (this.pending) {
      const request = this.pending;
      if (request.loading) return div().h(0);
      if (request.project) {
        const space =
          request.created &&
          spaces().find(
            (space) =>
              space.id === request.created &&
              (space.machine ?? null) === (request.project.machine ?? null) &&
              folderKey(space.folder) === folderKey(request.project.folder),
          );
        if (space) this.projectReady(request, space, true, cx);
        return div().h(0);
      }
      const space = spaces().find((space) => space.id === request.space);
      const tab = space?.tabs.find((tab) => tab.named && roleOf(tab.name) === request.role);
      if (tab || !space) {
        this.pending = null;
        if (tab) this.complete(request, space, tab);
        this.drain(cx);
      }
    }
    return div().h(0);
  }
}
