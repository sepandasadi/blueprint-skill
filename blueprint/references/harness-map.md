# Harness map — the only place tool names appear

The skill body speaks in actions. Resolve each action here for the harness you detect. Trust your actual tool list over this table when they disagree, and fall back to the next row down.

## Contents
- Detecting the harness
- Action → tool table
- Parallel dispatch details
- Model tiers
- Asking the user and gates

## Detecting the harness

Look at the tools you actually have, in this order:
| You have … | Harness |
|---|---|
| `Agent`, `AskUserQuestion`, `TodoWrite` or `TaskCreate` | Claude Code |
| `spawn_agent`, `wait_agent` | Codex (multi-agent on) |
| `invoke_subagent`, `write_to_file` with artifacts | Antigravity |
| a skill tool and "ask questions" tool but no subagent spawner | Cursor |
| `runSubagent`, or skills with `context: fork` only | VS Code / GitHub Copilot |
| none of the above | generic: sequential, chat-only |

Record the detected harness in `plan.md › Rulings` as `Ruling: harness = <name> — detected from tool list — cost if wrong: dispatch falls back to sequential`.

## Action → tool table

| Action in the skill | Claude Code | Codex | Antigravity | Cursor | VS Code Copilot | Generic |
|---|---|---|---|---|---|---|
| Dispatch a fresh-context reviewer | `Agent` (subagent_type general-purpose; prompt includes file paths) | `spawn_agent {fork_turns:"none"}` then `wait_agent` | `invoke_subagent` type `research` | sequential stance switch | stance switch (or a `context: fork` skill if configured) | stance switch |
| Dispatch implementers in parallel | several `Agent` calls in one message | several `spawn_agent` calls, then `wait_agent` in 5–10 min stretches | `invoke_subagent` type `self`, one at a time unless concurrent dispatch is available | sequential, you implement | sequential, you implement | sequential, you implement |
| Ask the user a batch | chat (numbered batch); `AskUserQuestion` only for the interpretation pick and gates | chat | chat | chat or the ask-questions tool | chat | chat |
| Track tasks | the task-list tool if present (`TaskCreate`, `TodoWrite`), else `plan.md` checkboxes | chat + `plan.md` checkboxes | task artifact: `write_to_file` with `IsArtifact: true`, `ArtifactType: "task"` | `plan.md` checkboxes | `plan.md` checkboxes | `plan.md` checkboxes |
| Read / write files | `Read`, `Write`, `Edit` | shell + apply_patch | `view_file`, `write_to_file`, `replace_file_content` | native edit tools | native edit tools | native tools |
| Worktrees | `EnterWorktree` if present, else `git worktree add` | `git worktree add` (sandbox may block branches) | `git worktree add` | `git worktree add` | `git worktree add` | `git worktree add` |

## Parallel dispatch details

- **Claude Code:** independent `Agent` calls in a single assistant message run concurrently. Give each the impl-plan path and the rules block from `parallel-execution.md › Dispatch`. Results arrive as notifications; do not poll.
- **Codex:** requires `[features] multi_agent = true` in `~/.codex/config.toml`. Spawn with `fork_turns: "none"` so the child starts clean; set `model` and `reasoning_effort` explicitly on every spawn; use `followup_task` for fix rounds instead of a new child; wait with `wait_agent` in 5–10 minute stretches, never short polls.
- **Antigravity:** no todo tool; keep the task artifact current. If only one `invoke_subagent` can run at a time, treat it as sequential dispatch.
- **Cursor / Copilot / generic:** implement sequentially yourself. The impl plans still exist so a later session, or a different harness, can parallelize.

## Model tiers

| Role | Tier | Claude Code | Codex |
|---|---|---|---|
| implementer | standard | `model: "sonnet"` on `Agent` | a mid-tier preset from your spawn allowlist |
| reviewer, builder check, convergence | most capable | `model: "opus"` on `Agent` | the strongest preset on your allowlist |
Other harnesses: use whatever the subagent tool allows; otherwise the current session model.

## Asking the user and gates

- Gates are chat messages that end with one question and wait. Approval is an explicit affirmative ("yes", "approved", "go"). Silence, "looks good so far", or a new unrelated request is not approval.
- In Claude Code the gate question may use `AskUserQuestion` with options `Approve` / `Change something`.
- "Yes, but change X" → apply X, re-run only the review pass it touches (counts as a cycle), show the diff of the plan, ask again.
