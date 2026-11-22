# Olist Delivery Reliability and Customer Experience

## Objective

Identify which delivery delays are associated with low purchase ratings and which operational segments deserve investigation. Deliver evidence of SQL and Excel skills for Agoda CEG and BJC Big C, plus a measured database exercise for Agoda Data. The audience is an operations analyst deciding where to investigate delays or pilot customer notifications.

## Scope decisions

The first release uses Olist alone, PostgreSQL for metrics, Python for loading and exploratory checks, and Excel for the dashboard. Use VS Code as the workspace. A notebook is optional for exploration. A proposed notification pilot is an experiment design, with no estimate of causal benefit from this observational analysis. The source has purchase reviews and delivery milestones. Agent performance, support tickets and verified customer loyalty are outside its coverage.

## Phase 1 — Acquire and audit (2–3 hours)

- Download the publisher CSV archive, record the release, acquisition date and SHA-256, and keep raw data outside version control. Review licence terms before sharing derivatives.
- Start with orders, customers, order items, products, category translations and reviews. Add payments only if needed for a question. Inspect actual headers before writing the schema.
- Report row counts, key uniqueness, foreign-key coverage, missing dates, impossible timestamp order, and multiple reviews per order. Inspect whether reviews occur before delivery.
- Start with orders purchased in 2017 and audit observed follow-up before freezing the window. Record the cohort rules and a snapshot cutoff. Report order statuses separately and document every exclusion.

## Phase 2 — Model and validate the data (4–6 hours)

- Use PostgreSQL locally. Use a single database and a simple repeatable load command. Keep typed staging tables and a documented order-level analysis view.
- Validate keys before applying constraints. Preaggregate items and reviews before joining to orders. Use a deterministic latest-review rule with documented timestamp and tie-break fields after inspecting the source. Keep unrated orders in the view.
- Assign multi-category orders to a distinct group for order-level comparisons. Preserve a separate item-grain view only if needed for category breakdowns.
- Check that one row survives per order, source and final order counts reconcile, and item totals do not multiply after the join. Check known cases by hand.
- For Agoda Data, benchmark one selective operations query before and after an index using EXPLAIN ANALYZE with buffers and comparable runs. Record any neutral or negative result.

## Phase 3 — Answer the business question (4–5 hours)

| Metric | Definition and eligibility |
| --- | --- |
| On-time delivery | Actual delivery date on or before promised date among eligible deliveries. Require both dates and an actual delivery timestamp at or after purchase and before the cutoff. Compare calendar dates and record the timestamp convention. |
| Delay severity | Actual delivery date minus promised date, with delay bands of on time, 1–2, 3–7 and 8+ days. Report median and p90 delay for late orders. |
| Low-rating share | Orders with selected review scores 1–2 divided by orders with valid selected scores. |
| Review coverage | Orders with valid selected scores divided by eligible orders, reported alongside low-rating share. |
| Time by stage | Purchase to approval, approval to carrier handoff, and handoff to delivery, using valid timestamp pairs and reporting each denominator. |

Compare delay bands by purchase month, customer state and category. Show counts and suppress comparisons below 30 eligible observations, with a separate minimum of 30 reviews for low-rating comparisons. Check sensitivity to review-selection rules and to excluding reviews recorded before delivery. Compare late and on-time orders within similar cohorts. Recommend investigations by volume and severity. Test notification ideas with an experiment whose outcome includes review coverage and a customer experience measure.

## Phase 4 — Excel and presentation (5–7 hours)

- Export the order-level dataset for a refreshable workbook. Use a data tab, metric definitions, QA checks, PivotTables and a summary with purchase month and customer state filters. Follow the [Phase 4 handoff](reports/phase-4-handoff.md) for the CSV schema, workbook refresh and filter checks.
- Reproduce three SQL totals and rates independently using COUNTIFS, SUMIFS or pivots. Keep formulas visible and reconcile results under the same filters. Manually verify refresh and filters in Excel. Use the overall and November 2017 São Paulo targets in the handoff, with exact counts, rates matching to two decimal places and blank rates for zero denominators.
- Publish the reproducible scripts, an ER diagram, aggregate charts and a one-page memo with evidence, recommended actions, and limitations when ready. Use the dataset attribution in the README. Track the diagram in `reports/schema.md` and aggregate charts under `reports/charts/`. Keep the workbook local until redistribution of its underlying order data is cleared.
- A release is ready when a fresh run reproduces the core metrics, Excel ties to SQL, and every recommendation links to evidence. A dashboard and predictive model beyond the workbook are optional follow-ups.

## Implementation contract

- Freeze purchases from 2017-01-01 inclusive to 2018-01-01 exclusive. Use the fixed 2018-06-01 exclusive cutoff for observable milestones and reviews. Report past-promise orders without observed delivery by source status, including terminal statuses. Exclude those orders from delivered-order rates. Publish status and exclusion counts.
- Restrict the primary rating comparison to delivered orders with valid actual and promised dates. Compare late vs on-time low-rating share in percentage points among rated orders. Report review coverage using all eligible deliveries in each arm. Compare within state, purchase month, or category and require at least 30 rated orders per arm for a rating comparison. Rank each dimension by the `All late` row in script 05 and show p90 delay and low-rating share alongside volume. Script 07 compares the five known states with the most late orders and at least 30 late orders each, with a minimum of 30 valid pairs per stage and arm.
- Take the latest valid 1–5 rating observed before cutoff by review answer timestamp. Resolve ties by review ID then stable source row number. For the timing sensitivity, exclude reviews created before the delivery calendar date and reselect the latest eligible answer. For ranking sensitivity, select the earliest eligible answer using the same tie-break fields and no creation-date filter. Report coverage changes. Log conflicting scores tied on order, answer timestamp and review ID before the source-row tiebreaker.
- Keep load logic in `load.py` with a transaction that refreshes staging consistently. Implement the view and metric queries in `sql/`. Export to `data/exports/orders.csv`, build `reports/operations.xlsx`, and write `reports/findings.md`. Reconcile eligible order count, on-time share and low-rating share from SQL and Excel both overall and for one matching monthly/state filter. Require exact integer matches and rate agreement within rounding.
- The index benchmark is open. Use orders joined to customers for SP purchases from November 1 through November 7, 2017. Compare three measured warm runs per arm with identical SQL and inputs, using a test index on `staging.orders (order_purchase_timestamp)` created inside a transaction that rolls back. Record result parity, scans, buffers and elapsed times in `reports/index-benchmark.md`.
- In a notification pilot, randomize eligible orders with a predicted missed promise to current practice or proactive notification. Define the review outcome, coverage, and any available support contact rate before running it.

## Initial audit results

The initial 2017 slice includes 43,428 orders marked delivered. Of those, 43,426 have actual and promised dates, 43,100 have at least one matched review, and 315 have multiple review rows. These are coverage checks before the final eligibility rules. Approval-to-carrier timestamps are inverted in 83 cases and carrier-to-customer timestamps in 19. Apply validity separately per stage. Within the highest-volume late segments, compare median and p90 stage durations for late and on-time orders and report valid counts for each phase. Treat differences as leads for investigation.

## 2017 follow-up audit

Run `sql/03_audit_2017_followup.sql` after building the order summary, using
the same psql command in the README with the audit script as input. It reports
counts by source status and for the entire 2017 purchase cohort.

Keep June 1, 2018 exclusive as the analysis cutoff. The 45,101 purchases have
no missing promised dates. All 43,426 recorded customer deliveries occurred
before the cutoff and meet the primary delivery eligibility rules. Two more
orders marked delivered have no customer delivery timestamp. The 1,675 orders
with a past promise and no observed delivery include canceled and unavailable
orders, so inspect the status breakdown before treating that count as an open
backlog. Source statuses reflect the extract. The audit cannot establish when
an undated status change occurred.

## Closure evidence

See the [Phase 4 handoff](reports/phase-4-handoff.md) for verified results and remaining manual checks. The acquisition date and publisher release identifier remain open if recoverable. Script 08 records source key, relationship, and review tie checks.
