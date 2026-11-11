---
name: temporary-workarounds
description: Use when the user asks to record, find, review, or remove temporary workarounds, revisit known issues or pending upstream fixes, or check whether an old workaround is still needed. The user's tracker lives in ~/Wiki/temporary_workarounds/.
---

# Temporary workarounds

## Where to look

The source of truth is the user's wiki:

- Index: `~/Wiki/temporary_workarounds/index.md`
- Individual notes: `~/Wiki/temporary_workarounds/*.md`

Expand `~` to the user's home directory regardless of the current project.
Always start with the index, then read the relevant notes. List the folder too
when searching or reviewing everything, since the user may add notes manually
before linking them from the index.

Keep issue details in the wiki. This skill describes the workflow and does not
need changing when another workaround is added.

## Record a workaround

1. Check for an existing entry and update it rather than creating a duplicate.
2. Use a descriptive snake_case filename and the existing notes as a guide.
3. Record the problem, affected environment and versions, the exact workaround,
   and why it helps. Distinguish observed results from suspected causes.
4. Record where the workaround is configured and its scope. For managed dotfiles,
   include both the chezmoi source and deployment target. Distinguish a tested
   one-off command, a proposed export, and an enabled persistent setting. Mark
   unknown locations explicitly; never infer that a setting was applied.
5. Include upstream issue or PR URLs, the date their status was checked, and
   concrete removal and verification steps. Keep URLs visible. Omit credentials.
6. Add or update the index row with the same status and last-checked date.

## Review pending fixes

Read the note and check current upstream evidence. Separate these milestones:

1. The fix was merged.
2. A release containing the fix shipped.
3. The required versions are installed and running locally.
4. The original workflow works with the workaround removed.

Check every relevant component, such as both client and server. If local version
inspection is unavailable, report that gap. Do not treat a closed issue or merged
PR alone as proof that the workaround can be removed.

Use **Active** while the workaround is needed or unassessed, **Ready to test**
when a fix has shipped but removal is unverified, and **Resolved** after successful
removal and verification. Record checked dates and results in the note and index.

A request to review status is not a request to upgrade software or alter its
configuration. Follow the user's requested scope and the repository's editing
rules when implementing removal. Edit managed sources and apply scoped targets.

## Retire a workaround

Use the note's removal procedure and reproduce the original failing workflow.
Also check any behaviour the workaround was meant to preserve. If verification
fails, retain or restore the workaround and record the failure.

After successful removal, mark the note and index Resolved and record the date,
tested versions, configuration changes, and result. Keep the resolved note as
history so future sessions can explain why the old setting existed.
