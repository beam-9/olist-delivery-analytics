-- Zero means the key is unique and non-null across the complete extract.
SELECT 'orders.order_id' AS source_key, count(*) - count(DISTINCT order_id) AS defective_rows FROM staging.orders
UNION ALL SELECT 'customers.customer_id', count(*) - count(DISTINCT customer_id) FROM staging.customers
UNION ALL SELECT 'items.(order_id, order_item_id)', count(*) - count(DISTINCT (order_id, order_item_id))
    FILTER (WHERE order_id IS NOT NULL AND order_item_id IS NOT NULL) FROM staging.order_items
UNION ALL SELECT 'products.product_id', count(*) - count(DISTINCT product_id) FROM staging.products
UNION ALL SELECT 'translations.category', count(*) - count(DISTINCT product_category_name) FROM staging.category_translations
UNION ALL SELECT 'reviews.source_row_number', count(*) - count(DISTINCT source_row_number) FROM staging.reviews;

-- Products with missing translations retain the original category in the order view.
SELECT 'order/customer' AS relationship, count(*) AS unmatched
FROM staging.orders o LEFT JOIN staging.customers c USING (customer_id) WHERE c.customer_id IS NULL
UNION ALL SELECT 'item/order', count(*)
FROM staging.order_items i LEFT JOIN staging.orders o USING (order_id) WHERE o.order_id IS NULL
UNION ALL SELECT 'item/product', count(*)
FROM staging.order_items i LEFT JOIN staging.products p USING (product_id) WHERE p.product_id IS NULL
UNION ALL SELECT 'review/order', count(*)
FROM staging.reviews r LEFT JOIN staging.orders o USING (order_id) WHERE o.order_id IS NULL
UNION ALL SELECT 'named product/category', count(*)
FROM staging.products p LEFT JOIN staging.category_translations t USING (product_category_name)
WHERE p.product_category_name IS NOT NULL AND t.product_category_name IS NULL;

-- Different scores at this grain are resolved by the stable source row number.
SELECT order_id, review_answer_timestamp, review_id,
       array_agg(DISTINCT review_score ORDER BY review_score) AS conflicting_scores
FROM staging.reviews
WHERE review_score BETWEEN 1 AND 5
  AND review_answer_timestamp < timestamp '2018-06-01'
GROUP BY order_id, review_answer_timestamp, review_id
HAVING count(DISTINCT review_score) > 1
ORDER BY order_id, review_answer_timestamp, review_id;
