# Olist Delivery Reliability and Customer Experience

A PostgreSQL and Excel study of delivery delays and purchase ratings for 2017 orders in the [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

**[Read the research paper (PDF)](reports/olist-delivery-reliability-study.pdf)** · [Findings and proposed experiment](reports/findings.md) · [Schema](reports/schema.md) · [Excel QA](reports/phase-4-handoff.md)

## Findings

- Of 43,426 eligible deliveries, 40,973 (94.35%) arrived by the promised date.
- São Paulo and Rio de Janeiro accounted for 1,274 of 2,453 late deliveries (51.9%).
- The low-rating gap between late and on-time orders narrowed from 52.34 to 16.47 percentage points when reviews were restricted to those created on or after the delivery date. Late-order review coverage fell from 97.11% to 24.79%.

[Late deliveries by state](reports/charts/late-by-state.svg) · [Rating sensitivity](reports/charts/rating-sensitivity.svg)

## Tech stack

| Technology | Why we used it | How we used it |
| --- | --- | --- |
| Python 3 | Make data checks and loading repeatable | Audit CSV headers and row counts, then load six source tables in a transaction. |
| PostgreSQL and SQL | Analyse delivery and review data at one row per order | Build the 2017 cohort, calculate metrics, test review-selection rules, and benchmark a timestamp index. |
| Docker Compose | Make local database setup reproducible | Start PostgreSQL and run the analysis scripts through the container's `psql` client. |
| Excel and Power Query | Check SQL results in a spreadsheet and explore filtered totals | Import the order export and use PivotTables to reconcile overall and November 2017 São Paulo counts. |
| LaTeX, BibTeX, and Tectonic | Produce a reproducible research paper | Typeset the manuscript and figures, manage references, and compile the PDF. |

## Reproduce the analysis

With Python 3 and Docker Compose, place the six required Olist CSVs in `data/raw/` and run the following from the repository root. The dataset is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Source files and the working Excel workbook stay local.

```sh
(
  set -e
  python3 audit.py
  docker compose up -d --wait
  python3 load.py
  for file in sql/0[1-9]_*.sql; do
    docker compose exec -T postgres psql -X -w -v ON_ERROR_STOP=1 -U olist -d olist -f - < "$file"
  done
)
```

For a native PostgreSQL connection, use `python3 load.py --psql /path/to/psql` with the appropriate connection environment. See [compose.yaml](compose.yaml) for the local database configuration and the [Excel handoff](reports/phase-4-handoff.md) for the export and reconciliation steps.

The original nine-file archive was downloaded from Olist’s Kaggle endpoint. SHA-256: `967e41e04fc306fe604e2a693f488995a8b41e5047418f8a5c8e4abd6deca784`.
