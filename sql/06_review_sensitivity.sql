WITH post_delivery_review AS (
    -- Most creation timestamps are midnight. Keep same-day reviews to avoid treating midnight as precise.
    -- Filter before ranking so an earlier eligible review can replace the primary review.
    SELECT DISTINCT ON (r.order_id) r.order_id, r.review_score
    FROM staging.reviews r
    JOIN public.delivery_cohort_2017 c USING (order_id)
    WHERE r.review_score BETWEEN 1 AND 5
      AND r.review_answer_timestamp < timestamp '2018-06-01'
      AND r.review_creation_date::date >= c.order_delivered_customer_date::date
    ORDER BY r.order_id, r.review_answer_timestamp DESC,
             r.review_id DESC NULLS LAST, r.source_row_number DESC NULLS LAST
), counts AS (
    SELECT c.delay_days > 0 AS late,
           count(*) AS eligible_orders,
           count(c.review_score) AS primary_rated,
           count(r.review_score) AS sensitivity_rated,
           count(*) FILTER (WHERE c.review_score <= 2) AS primary_low,
           count(*) FILTER (WHERE r.review_score <= 2) AS sensitivity_low
    FROM public.delivery_cohort_2017 c
    LEFT JOIN post_delivery_review r USING (order_id)
    GROUP BY 1
)
SELECT *,
       round(100.0 * (sensitivity_rated - primary_rated) / eligible_orders, 2) AS coverage_change_pp,
       round(100.0 * primary_low / nullif(primary_rated, 0), 2) AS primary_low_rating_pct,
       round(100.0 * sensitivity_low / nullif(sensitivity_rated, 0), 2) AS sensitivity_low_rating_pct
FROM counts ORDER BY late;

-- Change answer ordering alone to distinguish selection effects from timing exclusions.
WITH earliest_review AS (
    SELECT DISTINCT ON (r.order_id) r.order_id, r.review_score
    FROM staging.reviews r
    WHERE r.review_score BETWEEN 1 AND 5
      AND r.review_answer_timestamp < timestamp '2018-06-01'
    ORDER BY r.order_id, r.review_answer_timestamp ASC,
             r.review_id DESC NULLS LAST, r.source_row_number DESC NULLS LAST
)
SELECT c.delay_days > 0 AS late,
       count(*) AS eligible_orders,
       count(c.review_score) AS latest_rated,
       count(r.review_score) AS earliest_rated,
       count(*) FILTER (WHERE c.review_score IS DISTINCT FROM r.review_score) AS changed_scores,
       round(100.0 * count(*) FILTER (WHERE c.review_score <= 2) / nullif(count(c.review_score), 0), 2)
           AS latest_low_rating_pct,
       round(100.0 * count(*) FILTER (WHERE r.review_score <= 2) / nullif(count(r.review_score), 0), 2)
           AS earliest_low_rating_pct
FROM public.delivery_cohort_2017 c
LEFT JOIN earliest_review r USING (order_id)
GROUP BY 1 ORDER BY 1;
