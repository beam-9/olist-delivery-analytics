"""Check required Olist files and report their row counts and headers."""
import csv
from pathlib import Path

RAW = Path(__file__).resolve().parent / "data" / "raw"
REQUIRED = {
    "olist_orders_dataset.csv": {"order_id", "customer_id", "order_status", "order_purchase_timestamp", "order_delivered_customer_date", "order_estimated_delivery_date"},
    "olist_customers_dataset.csv": {"customer_id", "customer_state"},
    "olist_order_items_dataset.csv": {"order_id", "order_item_id", "product_id"},
    "olist_products_dataset.csv": {"product_id", "product_category_name"},
    "product_category_name_translation.csv": {"product_category_name", "product_category_name_english"},
    "olist_order_reviews_dataset.csv": {"order_id", "review_id", "review_score", "review_answer_timestamp"},
}

if __name__ == "__main__":
    missing = [name for name in REQUIRED if not (RAW / name).is_file()]
    if missing:
        raise SystemExit("Missing original CSVs in data/raw: " + ", ".join(missing))

    for name, required in REQUIRED.items():
        with (RAW / name).open(encoding="utf-8-sig", newline="") as source:
            rows = csv.DictReader(source)
            absent = required - set(rows.fieldnames or [])
            if absent:
                raise SystemExit(f"{name}: missing columns {sorted(absent)}")
            count = sum(1 for _ in rows)
            if not count:
                raise SystemExit(f"{name}: no data rows")
            print(f"{name}: {count:,} rows")
