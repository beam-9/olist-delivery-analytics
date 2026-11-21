# Phase 4 handoff

## Verified starting point

On November 21, 2026, the six source CSVs passed the header and row-count
audit, the loader refreshed staging, and all seven SQL scripts ran against
local PostgreSQL. The order view reconciled to 99,441 unique orders and
112,650 item rows, with all 768 orders lacking source reviews retained.
Order–customer, item–order, item–product, and review–order joins had no
unmatched rows. Thirteen products with a named category lacked a translation.
The order view falls back to the source category name. The calculated delay
matched the staging date difference for every eligible delivery.

| Phase | Verified | Open work |
| --- | --- | --- |
| 1 | Source counts, relationship coverage, cohort follow-up, status and timestamp audit | Record the acquisition date and publisher release if recoverable. Review source integrity output from script 08. |
| 2 | Transactional staging refresh, order grain, item reconciliation, and unrated orders | Run the planned index benchmark. Review selection and source key checks are tracked in scripts 02 and 08. |
| 3 | Overall and segmented metrics, pre-delivery review sensitivity, and stage comparisons | Turn findings into investigation priorities and specify the notification pilot. |

## Findings to carry forward

- **Review selection changes the picture.** In the primary analysis, low
  ratings were 61.54% of 2,382 rated late orders and 9.20% of 40,697 rated
  on-time orders. Using the latest review created on or after the delivery
  calendar date, the late share fell to 25.66% and coverage fell from 97.11%
  to 24.79%. Use both views and their denominators in the memo. Selecting the earliest eligible answer alone kept coverage fixed and moved the late low-rating share from 61.54% to 61.59%.
- **Start with São Paulo and Rio de Janeiro.** They had 650 and 624 late
  deliveries, respectively. In Rio de Janeiro, median carrier-to-delivery
  time was about 675 hours for late deliveries versus 193 hours for on-time
  deliveries. Use stage results to choose where to investigate operational
  records. The study measures associations.
- **Keep overdue reporting tied to source status.** The audit reports 1,675
  past-promise orders without observed delivery, including canceled and
  unavailable orders. The extract lacks timestamps for those status changes.

## Build and verify the workbook

1. Run the loader and SQL scripts in numerical order using the README
   commands. Finish the benchmark as a separate database milestone using the fixed slice and index in PLAN.md. Use a
   fixed state and purchase-date filter, repeated warm runs of the identical
   query, and record plans, buffer counts, elapsed times and matching result
   counts. Use an isolated transaction or database for the test index.
2. Add a reproducible export of `public.delivery_cohort_2017` to
   `data/exports/orders.csv`. Write one row per order, sorted by order ID,
   with a UTF-8 header and columns `order_id`, `purchase_month`,
   `customer_state`, `order_category`, `delay_days` and `review_score`.
   Preserve order IDs as text, use ISO dates, signed integer delay days,
   and blank fields for nulls. Verify the export has 43,426 unique IDs.
3. Build `reports/operations.xlsx` with a refreshable CSV connection,
   an Orders table, Definitions and QA tabs, PivotTables, and a summary
   filtered by purchase month and customer state. Use a configurable local
   CSV path. Keep blank review scores distinct from numeric scores on import.
4. Use spreadsheet formulas or pivots to reproduce the counts below. On-time
   share divides on-time orders by eligible orders. Low-rating share divides
   scores 1–2 by scores 1–5. Show blank when a denominator is zero. Require
   exact counts and rates matching SQL when displayed to two decimal places.
5. In Excel, refresh from the CSV, verify the all-orders totals, select
   November 2017 and SP together, verify the slice, then clear both filters
   and verify the overall totals return. Record Excel version and results.
6. Write `reports/findings.md`, add an ER diagram and aggregate charts, and
   cite the dataset using the README attribution. Include review coverage,
   limitations, investigation priorities and a randomized notification pilot
   proposal with a customer experience outcome. Keep raw and exported rows
   local. Check redistribution terms before publishing a workbook with data.

### SQL reconciliation targets

| Filter | Eligible | On time | Rated | Low ratings | On time | Low rating |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| All eligible 2017 deliveries | 43,426 | 40,973 | 43,079 | 5,211 | 94.35% | 12.10% |
| November 2017 and SP | 2,898 | 2,696 | 2,879 | 350 | 93.03% | 12.16% |

```sql
SELECT count(*) AS eligible,
       count(*) FILTER (WHERE delay_days <= 0) AS on_time,
       count(*) FILTER (WHERE review_score BETWEEN 1 AND 5) AS rated,
       count(*) FILTER (WHERE review_score BETWEEN 1 AND 2) AS low_ratings
FROM public.delivery_cohort_2017
WHERE purchase_month = DATE '2017-11-01' AND customer_state = 'SP';
```

Remove the WHERE clause for the overall case.

For workbook QA, compare Excel's 0–1 proportion formatted as a percentage
with SQL's 0–100 percentage. For investigation priorities, rank each
dimension using the `All late` rows from script 05, then show p90 delay and
the low-rating share beside late volume. The individual delay bands are
components of that total.
