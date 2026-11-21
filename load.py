"""Load the six Olist CSVs into PostgreSQL staging in one transaction."""
import argparse
import csv
import subprocess
import tempfile

from audit import RAW, REQUIRED

# Keep only fields needed for the delivery analysis and its quality checks.
TABLES = {
    "orders": ("olist_orders_dataset.csv", """
        order_id text, customer_id text, order_status text,
        order_purchase_timestamp timestamp, order_approved_at timestamp,
        order_delivered_carrier_date timestamp, order_delivered_customer_date timestamp,
        order_estimated_delivery_date timestamp
    """),
    "customers": ("olist_customers_dataset.csv", "customer_id text, customer_state text"),
    "order_items": ("olist_order_items_dataset.csv", """
        order_id text, order_item_id integer, product_id text, seller_id text,
        shipping_limit_date timestamp, price numeric, freight_value numeric
    """),
    "products": ("olist_products_dataset.csv", "product_id text, product_category_name text"),
    "category_translations": ("product_category_name_translation.csv", """
        product_category_name text, product_category_name_english text
    """),
    "reviews": ("olist_order_reviews_dataset.csv", """
        review_id text, order_id text, review_score integer,
        review_creation_date timestamp, review_answer_timestamp timestamp,
        source_row_number integer
    """),
}


def write_load(sql):
    sql.write("BEGIN;\nSELECT pg_advisory_xact_lock(716939);\n")
    sql.write("CREATE SCHEMA IF NOT EXISTS staging;\n")
    counts = {}
    for table, (filename, definition) in TABLES.items():
        columns = [column.strip().split()[0] for column in definition.split(",")]
        source_columns = [column for column in columns if column != "source_row_number"]
        with (RAW / filename).open(encoding="utf-8-sig", newline="") as source:
            rows = csv.DictReader(source)
            missing = (REQUIRED[filename] | set(source_columns)) - set(rows.fieldnames or [])
            if missing:
                raise ValueError(f"{filename}: missing columns {sorted(missing)}")
            sql.write(f"CREATE TABLE IF NOT EXISTS staging.{table} ({definition});\n")
            sql.write(f"TRUNCATE staging.{table};\n")
            sql.write(f"COPY staging.{table} ({', '.join(columns)}) FROM STDIN CSV;\n")
            writer = csv.writer(sql, lineterminator="\n")
            count = 0
            for count, row in enumerate(rows, start=1):
                values = [row[column] for column in source_columns]
                if None in values or None in row:
                    raise ValueError(f"{filename}: malformed data record {count}")
                if table == "reviews":
                    values.append(count)
                writer.writerow(values)
            if not count:
                raise ValueError(f"{filename}: no data rows")
            counts[table] = count
            sql.write("\\.\n")
    for table, count in counts.items():
        sql.write(f"""DO $$
BEGIN
    IF (SELECT count(*) FROM staging.{table}) <> {count} THEN
        RAISE EXCEPTION 'Row count mismatch in staging.{table}';
    END IF;
END
$$;
""")
    sql.write("COMMIT;\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--psql", help="Path to local psql. Defaults to the Docker Compose client.")
    args = parser.parse_args()
    command = ["docker", "compose", "exec", "-T", "postgres", "psql"]
    if args.psql:
        command = [args.psql, "-h", "127.0.0.1", "-p", "5433"]
    command += ["-X", "-w", "-v", "ON_ERROR_STOP=1", "-U", "olist", "-d", "olist"]
    try:
        with tempfile.TemporaryFile(mode="w+", encoding="utf-8", newline="") as sql:
            write_load(sql)
            sql.seek(0)
            subprocess.run(command, stdin=sql, cwd=RAW.parents[1], check=True)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Load failed: {error}\n")


if __name__ == "__main__":
    main()
