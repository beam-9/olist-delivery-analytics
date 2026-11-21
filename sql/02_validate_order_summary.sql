-- Expected counts apply to the original Olist release used by this project.
BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;

WITH source_items AS (
    SELECT order_id, count(*) AS item_count
    FROM staging.order_items GROUP BY order_id
), reviewed_orders AS (
    SELECT DISTINCT order_id FROM staging.reviews
), reconciled AS (
    SELECT
        v.order_id AS view_order_id,
        o.order_id AS source_order_id,
        v.item_count,
        v.review_source_row_number,
        coalesce(i.item_count, 0) AS expected_items,
        r.order_id IS NULL AS no_source_review
    FROM staging.orders o
    FULL JOIN public.order_summary v USING (order_id)
    LEFT JOIN source_items i ON i.order_id = o.order_id
    LEFT JOIN reviewed_orders r ON r.order_id = o.order_id
), totals AS (
    SELECT
        count(view_order_id) AS view_rows,
        count(DISTINCT view_order_id) AS unique_orders,
        sum(item_count) AS summed_items,
        count(*) FILTER (WHERE view_order_id IS NULL OR source_order_id IS NULL) AS order_mismatches,
        count(*) FILTER (WHERE item_count IS DISTINCT FROM expected_items) AS item_mismatches,
        count(*) FILTER (WHERE source_order_id IS NOT NULL AND no_source_review) AS source_unreviewed,
        count(*) FILTER (WHERE source_order_id IS NOT NULL AND view_order_id IS NOT NULL
            AND no_source_review AND review_source_row_number IS NULL) AS retained_unreviewed,
        (SELECT count(*) FROM staging.order_items) AS source_items
    FROM reconciled
)
SELECT *,
    (view_rows = 99441 AND unique_orders = 99441 AND summed_items = 112650
     AND summed_items = source_items AND order_mismatches = 0 AND item_mismatches = 0
     AND source_unreviewed > 0 AND source_unreviewed = retained_unreviewed) IS TRUE AS passed
FROM totals
\gset

\echo View rows :view_rows / unique orders :unique_orders / item rows :summed_items of :source_items
\echo Orders without source reviews retained :retained_unreviewed of :source_unreviewed
\echo Order mismatches :order_mismatches / per-order item mismatches :item_mismatches
\if :passed
    \echo Order summary checks passed.
\else
    DO $$ BEGIN RAISE EXCEPTION 'Order summary reconciliation failed'; END $$;
\endif

COMMIT;
