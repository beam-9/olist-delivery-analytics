-- Read counts alongside rates. Coverage uses all eligible orders, and low-rating share uses rated orders.
SELECT count(*) AS eligible_orders,
       count(*) FILTER (WHERE delay_days <= 0) AS on_time_orders,
       count(review_score) AS rated_orders,
       count(*) FILTER (WHERE review_score <= 2) AS low_ratings,
       round(100.0 * count(*) FILTER (WHERE delay_days <= 0) / nullif(count(*), 0), 2) AS on_time_pct,
       round(100.0 * count(review_score) / nullif(count(*), 0), 2) AS review_coverage_pct,
       round(100.0 * count(*) FILTER (WHERE review_score <= 2) / nullif(count(review_score), 0), 2) AS low_rating_pct
FROM public.delivery_cohort_2017;

WITH segments AS (
    SELECT segment.dimension, segment.value, c.*,
           CASE WHEN delay_days <= 0 THEN 'On time'
                WHEN delay_days <= 2 THEN '1–2 days'
                WHEN delay_days <= 7 THEN '3–7 days'
                ELSE '8+ days' END AS delay_band
    FROM public.delivery_cohort_2017 c
    CROSS JOIN LATERAL (VALUES
        ('overall', 'All orders'),
        ('month', to_char(c.purchase_month, 'YYYY-MM')),
        ('state', coalesce(c.customer_state, 'unknown')),
        ('category', c.order_category)
    ) AS segment(dimension, value)
), totals AS (
    SELECT dimension, value,
           delay_band,
           count(*) AS eligible_orders,
           count(review_score) AS rated_orders,
           count(*) FILTER (WHERE review_score <= 2) AS low_ratings,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY delay_days) FILTER (WHERE delay_days > 0) AS median_late_days,
           percentile_cont(0.9) WITHIN GROUP (ORDER BY delay_days) FILTER (WHERE delay_days > 0) AS p90_late_days
    FROM segments
    GROUP BY dimension, value, delay_band
    UNION ALL
    SELECT dimension, value, 'All late', count(*), count(review_score),
           count(*) FILTER (WHERE review_score <= 2),
           percentile_cont(0.5) WITHIN GROUP (ORDER BY delay_days),
           percentile_cont(0.9) WITHIN GROUP (ORDER BY delay_days)
    FROM segments WHERE delay_days > 0 GROUP BY dimension, value
)
SELECT t.dimension, t.value, t.delay_band, t.eligible_orders, t.rated_orders, t.low_ratings,
       CASE WHEN t.eligible_orders >= 30 THEN round(100.0 * t.rated_orders / t.eligible_orders, 2) END AS review_coverage_pct,
       CASE WHEN t.rated_orders >= 30 THEN round(100.0 * t.low_ratings / t.rated_orders, 2) END AS low_rating_pct,
       CASE WHEN t.eligible_orders >= 30 THEN t.median_late_days END AS median_late_days,
       CASE WHEN t.eligible_orders >= 30 THEN t.p90_late_days END AS p90_late_days,
       -- Compare each eligible late arm with the on-time arm from the same segment.
       CASE WHEN t.delay_band <> 'On time' AND t.rated_orders >= 30 AND baseline.rated_orders >= 30
           THEN round(100.0 * (t.low_ratings::numeric / t.rated_orders
                              - baseline.low_ratings::numeric / baseline.rated_orders), 2)
       END AS low_rating_gap_pp
FROM totals t
LEFT JOIN totals baseline ON baseline.dimension = t.dimension
    AND baseline.value = t.value AND baseline.delay_band = 'On time'
ORDER BY t.dimension, t.value, t.delay_band;
