# Design notes — what blueprint borrows and why

Each mechanism below names the project it comes from, the file where it lives in that project, and where it lives in blueprint. Nothing was copied verbatim; the ideas were re-expressed to fit a single harness-neutral SKILL.md.

## From obra/superpowers
| Mechanism | Source | In blueprint |
|---|---|---|
| Hard approval gate ("nothing gets built until approved") | `brainstorming/SKILL.md` HARD-GATE | Iron rule + Gate 1 / Gate 2 |
| Builder check: fresh subagent lists questions whose answers change the build | `brainstorming/builder-check-prompt.md` | `review-checklists.md › Builder check` |
| Plan header: Global Constraints, Review Focus | `writing-plans/SKILL.md` | `templates.md › plan.md` |
| Per-task Interfaces consumes/produces; pre-flight conflict table | `writing-plans`, `subagent-driven-development › Setup` | `plan.md › Pre-flight conflict table`, impl plan Interfaces |
| Ledger lines `Ruling: … — why — cost if wrong`, `Task complete (commits, tests → result)` | `executing-plans/SKILL.md` | `templates.md › Progress Log ledger format` |
| Implementer statuses DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT | `subagent-driven-development` | ledger status words |
| Model tiers, named explicitly on dispatch | `subagent-driven-development › Model Selection` | `harness-map.md › Model tiers` |
| Skills speak in actions; per-harness tool mapping files | `using-superpowers/references/*-tools.md` | `harness-map.md` (the only file with tool names) |
| Rationalization tables | `executing-plans`, `verification-before-completion` | `SKILL.md › Red flags` |

Deliberate departure: superpowers forbids parallel implementers. blueprint allows them because its impl plans are partitioned by exclusive file ownership with frozen interfaces, and the orchestrator alone commits.

## From liustack/vibemaster
| Mechanism | Source | In blueprint |
|---|---|---|
| Open with 2–3 interpretations instead of a blank question | `shaping/SKILL.md` | Phase 1 opener |
| Never ask what the environment can answer | `shaping/SKILL.md` | Recon-first rule, recon checklists |
| Every decision carries grounds and what would reopen it | `shaping/SKILL.md` | `Decision / Grounds / Reopen if` entry format |
| Inferred content marked item by item | `references/publish.md` | `[inferred]` tag |
| Pre-finalize self-check: placeholders, contradictions, scope creep, untestable criteria | `shaping/SKILL.md` | `validation.md › Pre-gate self-check` |
| "Stance switch" review when no subagents, ending with what was checked | `coding/SKILL.md` | `review-checklists.md › Reviewer setup` |
| Resume: trust decisions, re-verify facts, write back drift | `snapshot/SKILL.md` | Resume procedure, `DRIFT` ledger line |

## From SuStackx0/Simflow
| Mechanism | Source | In blueprint |
|---|---|---|
| "Ambiguities (must resolve before starting)" section that blocks execution | `agents/planner.md` | `plan.md` and `impl-NN.md › Ambiguities (must be empty)` |
| Tasks grouped Parallel Group / Sequential Chain / Independent + Critical Path | `agents/planner.md` | `plan.md › Tasks`, `Critical path` |
| Requirement verdicts Satisfied / Partial / Gap / Conflict, Partial = Gap | `agents/reviewer.md` | `review-checklists.md › Coverage verdicts` |
| Review cycle counter, cap 3, re-run only the failing pass | `skills/review/SKILL.md` | fix loop in `review-checklists.md` |
| Post-run check for files touched by more than one agent | `skills/dispatch/SKILL.md` | multi-touched-file check in `parallel-execution.md › Commit policy` |
| Comprehension quiz before commit | `skills/understand/SKILL.md` | optional `quiz: on` at both gates |

## From github/spec-kit
| Mechanism | Source | In blueprint |
|---|---|---|
| Questions with a Recommended option and a "why it matters" line | `templates/commands/clarify.md` | three-line question format |
| Dated `## Clarifications / ### Session` Q → A log | `clarify.md` | every track file |
| Priority scope > security/privacy > UX > technical; trimmed items become Assumptions | `templates/commands/specify.md` | batch trim rule |
| Six-pass analysis with CRITICAL–LOW severities and a coverage table | `templates/commands/analyze.md` | `validation.md › The six passes` |
| Constitution gate + Complexity Tracking | `templates/plan-template.md` | optional `CONSTITUTION.md`, `plan.md › Constitution check` |
| `[P]` = no shared files and no unfinished dependencies | `templates/commands/tasks.md` | task line grammar |
| Convergence pass: completion claims are not evidence; append-only | `templates/commands/converge.md` | `plan.md › Convergence` |

## From morluto/rea
| Mechanism | Source | In blueprint |
|---|---|---|
| Installer: plan → dry-run → confirm → apply; copies not symlinks; backups; manifest-driven uninstall; `doctor` | `docs/installation.md` | `bin/blueprint-skill.js`, `install.sh` |
| "Read only the relevant guide" index keeping SKILL.md small | `SKILL.md` | `SKILL.md › Read only the relevant guide` |
| Closing pass grading every requirement answered / partial / unresolved | `SKILL.md` | Phase 7 final report |

## Added by blueprint
- Three-track interview in batches with recommended defaults.
- Cross-track traceability matrix as a hard precondition for planning.
- Dedicated bug / performance / security review passes over the plan, before code.
- 2–4 implementation plans by exclusive file ownership, each with Review log and Progress log; parallel implementers with an orchestrator-only commit policy.
- Simple / advanced modes that change depth, never gates.
- One SKILL.md for five harnesses plus an interactive installer with no runtime dependencies.
