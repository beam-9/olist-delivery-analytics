-- Match the exclusive review cutoff in 01_order_summary.sql.
WITH cohort AS (
    SELECT *, timestamp '2018-06-01' AS cutoff
    FROM public.order_summary
    WHERE order_purchase_timestamp >= timestamp '2017-01-01'
      AND order_purchase_timestamp < timestamp '2018-01-01'
)
SELECT
    CASE WHEN GROUPING(order_status) = 1 THEN 'ALL'
         ELSE coalesce(order_status, 'unknown') END AS source_status,
    count(*) AS orders,
    count(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS missing_promise,
    count(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_delivery,
    count(*) FILTER (WHERE order_delivered_customer_date >= cutoff) AS delivered_after_cutoff,
    -- This count includes terminal statuses such as canceled and unavailable.
    count(*) FILTER (
        WHERE order_estimated_delivery_date < cutoff
          AND (order_delivered_customer_date IS NULL OR order_delivered_customer_date >= cutoff)
    ) AS past_promise_without_observed_delivery,
    count(*) FILTER (
        WHERE order_status = 'delivered' AND order_delivered_customer_date < cutoff
          AND order_estimated_delivery_date IS NOT NULL
          AND order_delivered_customer_date >= order_purchase_timestamp
    ) AS eligible_deliveries,
    -- Count selected reviews across all orders in each source status.
    count(review_score) AS eligible_reviews,
    count(*) FILTER (WHERE order_approved_at < order_purchase_timestamp) AS inverted_purchase_to_approval,
    count(*) FILTER (WHERE order_delivered_carrier_date < order_approved_at) AS inverted_approval_to_carrier,
    count(*) FILTER (WHERE order_delivered_customer_date < order_delivered_carrier_date) AS inverted_carrier_to_delivery
FROM cohort
GROUP BY ROLLUP (order_status)
ORDER BY GROUPING(order_status), order_status;
