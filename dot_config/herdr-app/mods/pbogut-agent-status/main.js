import { View, div } from "gpui-kit";
import { connect } from "net";
import { agents, checking, props } from "herdr";

export default class AgentStatus extends View {
  init(_props, cx) {
    this.stopped = checking();
    this.port = props()?.port ?? 47653;
    this.latest = "";
    this.sent = "";
    this.socket = null;
    this.writing = false;
    if (!this.stopped) this.open(cx);
  }

  open(cx) {
    cx.spawn(async (cx) => {
      let socket;
      try {
        socket = await connect("127.0.0.1", this.port);
        if (this.stopped) {
          socket.close();
          return;
        }
        this.socket = socket;
        this.sent = "";
        this.flush(cx);
        // Wait for the helper to close. The native socket API times reads out
        // after 30 seconds; retrying that read sends no data to the helper.
        while (!this.stopped) {
          try {
            if ((await socket.read(1)) === null) break;
          } catch (error) {
            if (!/timed out|temporarily unavailable/i.test(String(error))) throw error;
          }
        }
      } catch (_) {
        // DMS can be stopped or reloading while the app stays open.
      } finally {
        socket?.close();
        if (this.socket === socket) this.socket = null;
        if (!this.stopped) {
          cx.timer.after(2000, (cx) => {
            if (!this.stopped) this.open(cx);
          });
        }
      }
    });
  }

  flush(cx) {
    if (!this.socket || this.writing || !this.latest || this.latest === this.sent) return;
    const socket = this.socket;
    this.writing = true;
    cx.spawn(async (cx) => {
      try {
        while (!this.stopped && this.socket === socket && this.latest !== this.sent) {
          const snapshot = this.latest;
          await socket.write(snapshot + "\n");
          if (this.socket === socket) this.sent = snapshot;
        }
      } catch (_) {
        socket.close();
      } finally {
        this.writing = false;
        if (!this.stopped && this.socket && this.socket !== socket) this.flush(cx);
      }
    });
  }

  render(cx) {
    if (!this.stopped) {
      const snapshot = agents()
        .map(({ address, status, focused }) => ({ address, status, focused }))
        .sort((a, b) => a.address.localeCompare(b.address));
      this.latest = JSON.stringify({ version: 1, agents: snapshot });
      this.flush(cx);
    }
    return div().h(0);
  }

  close() {
    this.stopped = true;
    this.socket?.close();
    this.socket = null;
  }
}
