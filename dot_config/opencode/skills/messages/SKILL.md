---
name: messages
description: Use when the user asks to check, read, search, or summarize chat messages, unread messages, or conversations. Access the user's chat applications in Ferdium through the chats-ferdium MCP connection. Discover available services and select the relevant application, account, or conversation based on the request.
---

# Messages

Use the `chats-ferdium` MCP tools to access the user's signed-in chat applications
in Ferdium. Discover services at runtime; there is no fixed list of applications.

## Find the service

1. Use `browser_tabs` to select Ferdium's main window, which has a `file://` URL.
2. Use `browser_snapshot` to inspect Ferdium's sidebar and service labels.
3. Run this function with `browser_evaluate` to discover loaded services:

```js
() => [...document.querySelectorAll('webview')].map(view => {
  const service = { partition: view.getAttribute('partition') };
  try {
    return { ...service, title: view.getTitle(), url: view.getURL() };
  } catch {
    return { ...service, unloaded: true };
  }
})
```

Match the request to the service title, URL, and sidebar label. Use its `partition`
to identify the account during subsequent calls. If the account or conversation
is ambiguous, ask a focused question. If a service is suspended or not loaded,
select it in Ferdium's sidebar, wait for it to load, and discover services again.

## Read the service

Electron exposes services as `webview` targets. Playwright's tab list and snapshots
cover the outer Ferdium window. Access each service's DOM through its webview's
`executeJavaScript` method using `browser_evaluate`.

Replace `PARTITION_FROM_DISCOVERY` with the chosen service's partition:

```js
async () => {
  const partition = 'PARTITION_FROM_DISCOVERY';
  const view = [...document.querySelectorAll('webview')]
    .find(view => view.getAttribute('partition') === partition);
  if (!view) throw new Error('Service not loaded; discover Ferdium services again');
  return view.executeJavaScript(`({
    title: document.title,
    text: (document.body?.innerText || '').slice(0, 12000)
  })`);
}
```

Start with the selected service's visible text. For further navigation or search,
inspect its controls and attributes inside `executeJavaScript`, then use selectors
observed in that DOM. Execute service interactions through the same webview.
Keep Ferdium's main window at its existing URL.

Read the requested conversations and time range. Refine extraction to the relevant
message elements, including senders and timestamps. Scroll or use the application's
search when needed; virtualized views only contain part of the conversation.
Report the application and account checked, findings, and any coverage limits.
State when a service needs login or could not be read.

Checking, reading, and summarizing messages are read-only tasks. Sending, replying,
editing, or deleting messages requires a request for that action.

## Connection problems

The MCP connects to Ferdium at `http://127.0.0.1:9225`. If it cannot connect, ask the
user to fully quit Ferdium and reopen it through the managed launcher. An existing
instance started without debugging flags needs a full restart.
If `chats-ferdium` tools are missing, the OpenCode configuration needs to be loaded
in a new session after restarting or reloading OpenCode.
