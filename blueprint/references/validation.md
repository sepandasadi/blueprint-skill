# Validation — making the three tracks agree

Run after the interview (Phase 2) and again as the pre-gate self-check before Gate 1 and Gate 2.

## Contents
- Traceability matrix
- The six passes
- Severity and routing
- Cycle cap
- Pre-gate self-check

## Traceability matrix

Build the table in `plan.md › Traceability matrix`. Rules:
- The matrix covers R-IDs only; `## Non-goals` entries have no IDs and are not in it.
- Every `R` maps to ≥ 1 `D` and ≥ 1 `T`. An `R` with no `D` is a HIGH finding (undesigned requirement); with no `T` a HIGH finding (untestable requirement).
- Every `D` and `T` cites ≥ 1 `R`. An orphan `D` is MEDIUM (gold-plating); an orphan `T` is LOW.
- After Phase 3, every `R` maps to ≥ 1 `W`; a `W` citing nothing is MEDIUM.

## The six passes

Read all three track files once per pass. Record findings as `<severity> <pass> <IDs>: <one sentence>`.

1. **Duplication** — two entries say the same thing with different IDs or words. Merge; keep the lower ID; strike the other with "merged into".
2. **Ambiguity** — unmeasurable adjectives (fast, secure, simple, robust, scalable, intuitive) or "etc." in a Decision line. Replace with a number, a threat, or an explicit list.
3. **Underspecification** — a Decision that a builder could implement two different ways and both would "satisfy" it. Typical: missing error behaviour, missing limits, missing owner of a record, missing "who can".
4. **Constitution alignment** — only when `docs/plans/CONSTITUTION.md` exists. Any MUST violated → CRITICAL. Any SHOULD violated without a Complexity Tracking row → HIGH.
5. **Coverage gaps** — the traceability matrix rules above, plus: every trust boundary in `design.md` has a negative `T`; every "dependency down" decision has a `T`.
6. **Inconsistency** — answers that cannot all be true. Classic shapes:
   - privacy vs capability (end-to-end encryption vs server-side search or content previews);
   - "never store X" vs "show X instantly without calling the source";
   - "no new dependencies" vs a design that needs one;
   - a performance target no chosen storage can meet;
   - scope words ("just the basics") vs a long list of extras in later answers;
   - terminology drift (the same thing called note / document / page).
   Show both entries verbatim to the user and ask which wins; record the loser's `Reopen if`.

## Severity and routing

| Severity | Meaning | Advanced mode | Simple mode |
|---|---|---|---|
| CRITICAL | plan would build the wrong thing or violate a MUST | ask the user now | ask the user now |
| HIGH | a builder would guess, and could guess wrong | ask the user now | fix with recommended default, tag `[inferred]`, list at Gate 1 |
| MEDIUM | quality or scope issue, outcome unchanged | fix, tag `[inferred]` | fix, tag `[inferred]` |
| LOW | cosmetic | fix silently | fix silently |

Questions to the user from validation use the same three-line format. HIGH questions count toward the follow-up cap; **CRITICAL questions are always asked, whatever the cap**. A CRITICAL question left unanswered is asked once more on its own; if it is still unanswered, stop before Phase 3. CRITICAL items are never resolved by a default.

Record every finding and its fix in `plan.md › Review log` under a `Validation cycle N of 3` entry.

## Cycle cap

Validation → fixes → validation again until no CRITICAL/HIGH remains, at most 3 cycles. On the third failure, stop and show the user the remaining findings with your recommended resolution for each; do not proceed to Phase 3 without their answer.

## Pre-gate self-check

Before showing any artifact at a gate, confirm all of these and say "Self-check: passed" (or list what failed and fix first):
- no `<placeholder>` text remains in any artifact;
- no `[inferred]` entry contradicts a confirmed entry;
- `## Ambiguities` is empty;
- no requirement, design or test item was added that the user did not ask for or accept (scope creep);
- every acceptance criterion names an observable outcome;
- the traceability matrix has no empty cell;
- in advanced mode: the Review log shows at least one completed cycle for this gate.
