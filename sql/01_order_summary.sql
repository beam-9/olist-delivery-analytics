-- One row per staged order. Apply purchase and delivery eligibility in downstream queries.
CREATE OR REPLACE VIEW public.order_summary AS
-- Aggregate before joining so multi-item orders still produce one row.
WITH items_by_order AS (
    SELECT
        i.order_id,
        count(*) AS item_count,
        sum(i.price) AS item_price_total,
        sum(i.freight_value) AS freight_total,
        count(DISTINCT p.product_category_name) AS category_count,
        min(coalesce(t.product_category_name_english, p.product_category_name)) AS category_name
    FROM staging.order_items AS i
    LEFT JOIN staging.products AS p ON p.product_id = i.product_id
    LEFT JOIN staging.category_translations AS t
        ON t.product_category_name = p.product_category_name
    GROUP BY i.order_id
),
latest_review AS (
    -- Use the exclusive cutoff recorded in PLAN.md. Source row breaks remaining ties.
    SELECT DISTINCT ON (order_id)
        order_id, review_id, review_score, review_creation_date,
        review_answer_timestamp, source_row_number
    FROM staging.reviews
    WHERE review_score BETWEEN 1 AND 5
      AND review_answer_timestamp < timestamp '2018-06-01'
    ORDER BY order_id, review_answer_timestamp DESC,
        review_id DESC NULLS LAST, source_row_number DESC NULLS LAST
)
SELECT
    o.order_id,
    o.customer_id,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    coalesce(i.item_count, 0) AS item_count,
    -- Use zero for orders without items and preserve null totals when item values are missing.
    CASE WHEN i.item_count IS NULL THEN 0 ELSE i.item_price_total END AS item_price_total,
    CASE WHEN i.item_count IS NULL THEN 0 ELSE i.freight_total END AS freight_total,
    CASE
        -- Only known source categories count toward the multi-category group.
        WHEN i.category_count > 1 THEN 'multiple_categories'
        ELSE coalesce(i.category_name, 'unknown')
    END AS order_category,
    r.review_id,
    r.review_score,
    r.review_creation_date,
    r.review_answer_timestamp,
    r.source_row_number AS review_source_row_number
FROM staging.orders AS o
LEFT JOIN staging.customers AS c ON c.customer_id = o.customer_id
LEFT JOIN items_by_order AS i ON i.order_id = o.order_id
LEFT JOIN latest_review AS r ON r.order_id = o.order_id;
