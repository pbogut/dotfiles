import { View, div } from "gpui-kit";
import { appHome, checking, exec, home, nextCommand, notify, readTextFile, run, setShared, shared, spaces } from "herdr";
import { commandFor, roleOf } from "./roles.js";
import { folderKey, loadProjectConfig, orderKey, projectOrder } from "./project.js";

export default class NamedTabs extends View {
  init(_props, cx) {
    this.queue = [];
    if (checking()) return;
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command.startsWith("project@")) {
          try {
            const project = JSON.parse(decodeURIComponent(command.slice(8)));
            if (!project.folder?.startsWith("/")) continue;
            if (![this.pending, ...this.queue].some((request) => request?.project &&
                folderKey(request.project.folder) === folderKey(project.folder))) {
              this.queue.push({ project });
            }
            this.drain(cx);
          } catch (error) {
            notify({ title: "Could not open project", body: String(error.message ?? error), level: "error" });
          }
          continue;
        }
        const [name, target, extra] = command.split("@");
        const role = roleOf(name);
        if (!role || extra !== undefined) continue;
        const space = target === undefined ? spaces().find((space) => space.active)?.id : target;
        if (!space) continue;
        if (![this.pending, ...this.queue].some((request) => !request?.layout && request?.space === space && request.role === role)) {
          this.queue.push({ role, space, explicit: target !== undefined });
        }
        this.drain(cx);
      }
    });
  }

  openProject(request, cx) {
    cx.spawn(async (cx) => {
      const project = request.project;
      try {
        request.config = await loadProjectConfig(project.folder, exec, readTextFile, `${appHome()}/herdr-project.json`);
      } catch (error) {
        request.config = { tabs: [] };
        notify({ title: "Could not load project configuration", body: String(error.message ?? error), level: "error" });
      }
      if (this.pending !== request) return;
      const existing = spaces().find((space) => project.id ? space.id === project.id
        : !space.machine && folderKey(space.folder) === folderKey(project.folder));
      if (existing) {
        run("space.select", { id: existing.id });
        this.projectReady(request, existing, false, cx);
      } else if (project.id) {
        this.pending = null;
        this.drain(cx);
      } else {
        request.before = new Set(spaces().map((space) => space.id));
        try {
          run("space.new", { name: project.label, folder: project.folder, machine: "" });
          this.timeout(request, project.label || project.folder, cx);
          cx.notify();
        } catch (error) {
          this.pending = null;
          notify({ title: "Could not open project", body: String(error.message ?? error), level: "error" });
          this.drain(cx);
        }
      }
    });
  }

  projectReady(request, space, created, cx) {
    const { config } = request;
    setShared(orderKey(space.id), config.tabs);
    const layout = { initial: created && config.tabs.length ? space.tabs[0]?.id : null };
    this.queue.unshift(...config.tabs.map((role, index) => ({
      space: space.id, role, layout, config, last: index === config.tabs.length - 1,
    })));
    this.pending = null;
    this.drain(cx);
  }

  complete(request, space, tab, created) {
    if (created || request.layout) {
      const roles = shared(orderKey(space.id)) ?? [];
      [...space.tabs].sort((a, b) => projectOrder(a, b, roles)).forEach((tab, index) => {
        run("tab.move", { id: tab.id, index: index + 1 });
      });
    }
    if (request.layout) {
      const initial = space.tabs.find((tab) => tab.id === request.layout.initial && !tab.named && tab.panes === 1);
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
    const initial = space.tabs.find((tab) => tab.id === request.layout.initial && !tab.named && tab.panes === 1);
    const roles = shared(orderKey(space.id)) ?? [];
    if (initial && space.tabs.some((tab) => tab.named && roles.includes(roleOf(tab.name)))) {
      run("tab.close", { id: initial.id });
    }
    request.layout.initial = null;
  }

  timeout(request, name, cx) {
    cx.timer.after(15000, (cx) => {
      if (this.pending !== request) return;
      this.pending = null;
      this.closeInitial(request, spaces().find((space) => space.id === request.space));
      notify({ title: `Could not create ${name}`, body: "It did not appear. Try opening it again.", level: "error" });
      this.drain(cx);
    });
  }

  loadDev(request, space, cx) {
    request.loading = true;
    cx.spawn(async (cx) => {
      try {
        request.config = await loadProjectConfig(space.folder, exec, readTextFile, `${appHome()}/herdr-project.json`);
      } catch (error) {
        notify({ title: "Could not load dev command", body: String(error.message ?? error), level: "error" });
      }
      if (this.pending !== request) return;
      request.loading = false;
      this.pending = null;
      // Recheck the space and existing tabs after the asynchronous file read.
      if (request.config) this.queue.unshift(request);
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
        this.complete(request, space, tab, false);
        continue;
      }
      this.pending = request;
      if (request.role === "dev" && !space.machine && !request.config) {
        this.loadDev(request, space, cx);
        continue;
      }
      const argv = commandFor(request.role, space, appHome(), home(), request.config?.dev);
      try {
        run("tab.new", {
          name: request.role, space: space.id, folder: space.folder || undefined, focus: false,
          // Replace the App's keep-open shell so program exit closes the pane.
          argv: argv ? ["exec", ...argv] : undefined,
        });
      } catch (error) {
        this.pending = null;
        this.closeInitial(request, space);
        notify({ title: `Could not create ${request.role}`, body: String(error.message ?? error), level: "error" });
        continue;
      }
      // Creation talks to the core. Wait for the actual tab in spaces(), not a delay.
      this.timeout(request, request.role, cx);
    }
  }

  render(cx) {
    if (this.pending) {
      const request = this.pending;
      if (request.loading) return div().h(0);
      if (request.project) {
        const space = request.before && spaces().find((space) => !space.machine && !request.before.has(space.id) &&
          folderKey(space.folder) === folderKey(request.project.folder));
        if (space) this.projectReady(request, space, true, cx);
        return div().h(0);
      }
      const space = spaces().find((space) => space.id === request.space);
      const tab = space?.tabs.find((tab) => tab.named && roleOf(tab.name) === request.role);
      if (tab || !space) {
        this.pending = null;
        if (tab) this.complete(request, space, tab, true);
        this.drain(cx);
      }
    }
    return div().h(0);
  }
}
