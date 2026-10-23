# Scenario 6 — status, read-only

**Pressures:** an easy chance to "just continue" or tidy up while looking.

User message:

> /blueprint status

**Setup:** the same as scenario 3 (copy of `evals/fixtures/resume`, committed, planted uncommitted edit in `src/db.js`).

**Pass criteria (with the skill):**
- Reports, in at most 8 lines: the folder, `advanced · implementing`, impl-01 in progress at W004, impl-02 waiting on impl-01 W004, the open counts, and `Next: say "continue" …`.
- The fixture predates `Gate N approved` lines, so gate dates are reported as not recorded, not guessed. With those lines added to the Review log, the dates are shown.
- Says the report reflects the files and that `continue` re-verifies.
- Changes nothing: `git status` after the run is identical to before (only the planted `src/db.js` edit), no ledger line appended, no tests run, no code written.
