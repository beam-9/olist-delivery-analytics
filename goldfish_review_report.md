# Goldfish annotated review report

**Target** [PLAN.md](PLAN.md), lines 1–71
**Round** 1. Implementation-readiness and codebase-details both completed.
**Status** Resolved for round 1. All nine proposed edits were accepted. Line references below refer to the reviewed revision.

| Finding | Severity and reviewer findings | Proposed resolution |
| --- | --- | --- |
| readiness-1-1, codebase-1-1 | Blocker. Lines 40–43 and 50 leave the export source, columns, null policy, workbook refresh and filters undefined. Script 04 supplies the same eligible grain that script 05 aggregates. | PROPOSE FIX. Reference the [Phase 4 handoff](reports/phase-4-handoff.md) for the CSV schema and Excel refresh contract. Use customer state throughout. |
| readiness-1-2, codebase-1-1 | Blocker. Lines 41–43 and 50 require a combined month and state check. Script 05 groups them separately. | PROPOSE FIX. Reference the handoff's November 2017 and SP comparator, exact counts, blank denominator rule, and two-decimal rate parity. |
| readiness-1-3, codebase-1-3 | Major. Lines 24 and 51 call for a benchmark. The repo has no measured result or benchmark script. | PROPOSE FIX. Mark it open and record a follow-up with fixed filters, repeat counts, index DDL and an evidence path. |
| readiness-1-4 | Major. Lines 13–23 promise source release, acquisition, integrity and manual checks. The existing scripts only reproduce part of that evidence. | PROPOSE FIX. Link the verified starting point in the handoff, list remaining provenance and manual checks, and require a tracked integrity query. |
| readiness-1-5, codebase-1-4 | Major. Lines 36 and 49 require sensitivity to selection and review timing, plus conflicting-tie logging. Script 06 changes timing eligibility and uses the primary latest-answer rule. | PROPOSE FIX. Specify a separate earliest-eligible-answer run with no creation-date filter. Log differing scores among rows tied on order, answer timestamp, and review ID before the source-row tiebreaker. |
| readiness-1-6, codebase-1-5, codebase-1-6 | Major. Lines 30, 36, 48 and 56 omit the delivery-at-or-after-purchase rule, leave stage scope implicit, and give no explicit ranking instruction. | PROPOSE FIX. State the delivery timestamp guard, document the five-state stage comparison, and rank each dimension by the `All late` row in script 05. |
| readiness-1-7 | Major. Line 47 calls the past-promise measure unresolved overdue while lines 67–71 and script 03 include canceled and unavailable orders. | PROPOSE FIX. Call the metric “past promise without observed delivery” and retain the source-status breakdown. |
| readiness-1-8, codebase-1-2 | Major. Lines 40–43 and 50 omit a publication rule for the workbook, which can store underlying order records. Paths for the diagram and charts are open. | PROPOSE FIX. Specify local workbook storage until redistribution is checked, and name tracked sources for the ER diagram and aggregate charts. |
| readiness-1-9 | Nit. Line 47 still proposes the cutoff fixed at line 64. README's main sequence skips script 03. | PROPOSE FIX. Use the fixed June 1, 2018 exclusive cutoff throughout and include script 03 in the reproduction sequence. |

## Ponytail repository audit

The repo loads six CSVs into local PostgreSQL and measures how delivery
delays relate to ratings. The expected load is one analyst refreshing the
original extract and running SQL locally.

### Should fix

1. **Review validation misses wrong scores.** In
   [script 02](sql/02_validate_order_summary.sql), a view that always returns
   null scores can still pass because the test checks only orders with no
   source review. Independently rank valid reviews and compare the selected
   score and source row against the view before using it for workbook QA.
2. **Same-day sensitivity treats all creation times as dates.** In
   [script 06](sql/06_review_sensitivity.sql), a review created earlier on the
   delivery day still passes. Document the calendar-day convention as the
   main sensitivity definition and add a strict-date comparison if the memo
   relies on a precise claim about pre-delivery timing.
3. **Eligible-count checks stop at the order view.** A change to the cohort
   filter in [script 04](sql/04_delivery_cohort.sql) could change workbook
   totals while script 02 still passes. Add the overall and month/state
   assertions from the handoff as a release check.

**Verdict** The current SQL baseline reproduces. Close the benchmark and
review validation gaps before treating Phases 1–3 as complete.

**Verification scope** Local Docker refresh, all seven SQL scripts, and
additional SQL checks. Excel refresh and the native host psql path remain unverified.
