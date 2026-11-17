import { View, div } from "gpui-kit";
import { appHome, checking, home, nextCommand, notify, run, spaces } from "herdr";
import { commandFor, compareTabs, roleOf } from "./roles.js";

export default class NamedTabs extends View {
  init(_props, cx) {
    this.queue = [];
    if (checking()) return;
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        const [name, target, extra] = command.split("@");
        const role = roleOf(name);
        if (!role || extra !== undefined) continue;
        const space = target === undefined ? spaces().find((space) => space.active)?.id : target;
        if (!space) continue;
        if (![this.pending, ...this.queue].some((request) => request?.space === space && request.role === role)) {
          this.queue.push({ role, space, explicit: target !== undefined });
        }
        this.drain(cx);
      }
    });
  }

  drain(cx) {
    while (!this.pending && this.queue.length) {
      const request = this.queue.shift();
      const space = spaces().find((space) => space.id === request.space);
      if (!space) continue;
      const tab = space.tabs.find((tab) => tab.named && roleOf(tab.name) === request.role);
      if (tab) {
        if (tab.name !== request.role) run("tab.rename", { id: tab.id, name: request.role });
        if (space.active || request.explicit) run("tab.select", { id: tab.id });
        continue;
      }
      this.pending = request;
      const argv = commandFor(request.role, space, appHome(), home());
      run("tab.new", {
        name: request.role, space: space.id, folder: space.folder || undefined, focus: false,
        // Replace the App's keep-open shell so program exit closes the pane.
        argv: argv ? ["exec", ...argv] : undefined,
      });
      // Creation talks to the core. Wait for the actual tab in spaces(), not a delay.
      cx.timer.after(15000, (cx) => {
        if (this.pending !== request) return;
        this.pending = null;
        notify({ title: `Could not create ${request.role}`, body: "The tab did not appear. Try the shortcut again.", level: "error" });
        this.drain(cx);
      });
    }
  }

  render(cx) {
    if (this.pending) {
      const request = this.pending;
      const space = spaces().find((space) => space.id === request.space);
      const tab = space?.tabs.find((tab) => tab.named && roleOf(tab.name) === request.role);
      if (tab || !space) {
        this.pending = null;
        if (tab) {
          [...space.tabs].sort(compareTabs).forEach((tab, index) => {
            run("tab.move", { id: tab.id, index: index + 1 });
          });
          if (space.active || request.explicit) run("tab.select", { id: tab.id });
        }
        this.drain(cx);
      }
    }
    return div().h(0);
  }
}
