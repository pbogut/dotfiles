# Agent switch

Local OpenCode V2 server plugin. OpenCode discovers this directory under
`~/.config/opencode/plugins/`.

The `switch_agent` tool takes `{"agent":"plan"}` or `{"agent":"build"}` and
switches the current session. Each switch checks the `switch_agent` permission
with the destination as its resource. The source agent is not part of the
resource. Selecting the current agent is a no-op.

Defaults live in the chezmoi source at
`dot_config/opencode/private_opencode.jsonc.tmpl`:

```json
{
  "permissions": [
    { "action": "switch_agent", "resource": "plan", "effect": "allow" },
    { "action": "switch_agent", "resource": "build", "effect": "ask" }
  ]
}
```

Change either effect to `allow`, `ask`, or `deny`. To require approval before
entering Plan, change its effect to `ask`. Normal OpenCode permission ordering
and saved approvals apply. The tool proposes no patterns to save, but existing
saved approvals can still satisfy an `ask` rule.

The plugin instructs Build to switch to Plan before review and completed-work
handoff. Review feedback stays a discussion in Plan, even when it asks for
corrections. Only explicit implementation approval permits requesting Build.
Accepting an increment also permits requesting Build for the next agreed
increment. A rejected switch is not retried automatically.

Switches run as standalone tool calls. The next model turn uses the selected
agent, so continuing does not require another user message. These workflow
instructions use ordinary Plan behavior, including its existing shell and
subagent permissions.

The context hook adapts the stock Plan reminder's manual-switch sentence in
outgoing requests. Stored history is not rewritten. The matched wording comes
from OpenCode 2.3.0; revisit it if upstream changes the reminder.

Run the source tests from the chezmoi repository with Node 22.18 or newer:

```sh
node --test assets/tests/opencode_agent_switch/switch.test.mjs
```
