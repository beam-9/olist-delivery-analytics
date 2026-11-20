# Olist Delivery Reliability and Customer Experience

Portfolio study of delivery performance and purchase reviews using the [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

**Status:** planning and data acquisition. See [the project plan](PLAN.md).

Place the original Olist CSV files in `data/raw/`. The raw files stay local. The publisher lists CC BY-NC-SA 4.0 for the dataset.

Run `python3 audit.py` to validate the required headers and count source records.

The original archive was acquired from the publisher’s Kaggle download endpoint. SHA-256: `967e41e04fc306fe604e2a693f488995a8b41e5047418f8a5c8e4abd6deca784`. The archive contained nine CSVs. The starter audit checks the six required inputs.
