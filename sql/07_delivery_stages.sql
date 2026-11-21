WITH priority_states AS (
    -- Late volume sets the investigation order before stage durations are compared.
    SELECT customer_state, count(*) AS late_orders
    FROM public.delivery_cohort_2017
    WHERE delay_days > 0 AND customer_state IS NOT NULL
    GROUP BY customer_state
    HAVING count(*) >= 30
    ORDER BY late_orders DESC, customer_state
    LIMIT 5
)
SELECT c.customer_state, c.delay_days > 0 AS late, stage.name AS stage,
       count(*) AS eligible_orders, count(stage.hours) AS valid_pairs,
       CASE WHEN count(stage.hours) >= 30 THEN
           round(percentile_cont(0.5) WITHIN GROUP (ORDER BY stage.hours)::numeric, 2)
       END AS median_hours,
       CASE WHEN count(stage.hours) >= 30 THEN
           round(percentile_cont(0.9) WITHIN GROUP (ORDER BY stage.hours)::numeric, 2)
       END AS p90_hours
FROM public.delivery_cohort_2017 c
JOIN priority_states p USING (customer_state)
CROSS JOIN LATERAL (VALUES
    ('Purchase to approval', c.purchase_to_approval_hours),
    ('Approval to carrier', c.approval_to_carrier_hours),
    ('Carrier to delivery', c.carrier_to_delivery_hours)
) AS stage(name, hours)
GROUP BY p.late_orders, c.customer_state, c.delay_days > 0, stage.name
ORDER BY p.late_orders DESC, c.customer_state, late, stage.name;
