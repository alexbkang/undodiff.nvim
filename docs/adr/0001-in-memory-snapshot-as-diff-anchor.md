# Accept undotree's in-place live-buffer mutation and diff via an in-memory snapshot anchor

- **Date**: 2026-09-01

## Context

Every decision revolves around one fact that undotree.nvim navigates real undo
history by rewriting the live source buffer immediately; those edits are real
buffer changes and are not rolled back when the plugin closes.

Ideas explored:

- Make undotree's navigation non-destructive: keep a copy of the original
  buffer, commit only on an explicit accept/enter, and restore on any other
  exit. This was rejected because the accept/restore state machine was more
  complexity than the feature justified.
- Using `:diffsplit` to open windows instead of managing windows ourselves.
  This was rejected because `:diffsplit` requires a file on disk to diff
  against. This would force temp files and cleanup.

## Decision
Keep undotree.nvim as the motor that mutates the live source. On open,
copy the current source lines into an in-memory snapshot buffer. The
snapshot is an origin anchor of where the file was at open, not a real
undo node (a real node would itself shift as the history navigates, so it
can't anchor a diff). Wire Neovim's native `:diffthis` between the
live source window and the snapshot window.

## Consequences

- Leaving a session leaves the live buffer where undotree last set it.
  No rollback to the pre-session state. This is not a bug.
