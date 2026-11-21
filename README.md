# Olist Delivery Reliability and Customer Experience

Portfolio study of delivery performance and purchase reviews using the [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

**Status:** data loaded into local PostgreSQL staging. See [the project plan](PLAN.md).

Place the original Olist CSV files in `data/raw/`. The raw files stay local. The publisher lists CC BY-NC-SA 4.0 for the dataset.

Run `python3 audit.py` to validate the required headers and count source records.

The original archive was acquired from the publisher’s Kaggle download endpoint. SHA-256: `967e41e04fc306fe604e2a693f488995a8b41e5047418f8a5c8e4abd6deca784`. The archive contained nine CSVs. The starter audit checks the six required inputs.

## Local PostgreSQL

Docker is optional. With Docker Desktop running, start the project database with
`docker compose up -d --wait`. Connect to `localhost:5433` using database and
username `olist` and the local development password in `compose.yaml`.
A native PostgreSQL installation also works. The CSV audit runs with Python
alone.

## Load the staging tables

With the PostgreSQL container running, execute `python3 load.py` from the
repository root. The loader uses the container's psql client and checks all six
staging row counts against the CSVs before committing. Re-running it refreshes
the same tables. It keeps fields used by the analysis and omits free-text review
comments. Review source row numbers count data records starting at 1.

To use a local psql client over the published port, set `PGPASSWORD` to the
development password in `compose.yaml` and run `python3 load.py --psql /path/to/psql`.

## Build and validate the order summary

After loading staging, run both scripts from the repository root.

```sh
docker compose exec -T postgres psql -X -w -v ON_ERROR_STOP=1 -U olist -d olist -f - < sql/01_order_summary.sql
docker compose exec -T postgres psql -X -w -v ON_ERROR_STOP=1 -U olist -d olist -f - < sql/02_validate_order_summary.sql
```

`public.order_summary` keeps one row per order and aggregates items before
joining them to orders. It selects the latest valid review answered before
June 1, 2018, with review ID and source row number breaking ties. All purchase
dates remain in the view so downstream queries can apply the 2017 cohort.
The validation script checks order IDs, item counts, and orders without reviews
against staging and exits with an error if reconciliation fails.
