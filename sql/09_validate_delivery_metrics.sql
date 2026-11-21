-- Check integer numerators and denominators before rounding rates for Excel.
WITH checks AS (
    SELECT slice.name, count(*) AS eligible, count(*) FILTER (WHERE c.delay_days <= 0) AS on_time,
           count(c.review_score) AS rated, count(*) FILTER (WHERE c.review_score BETWEEN 1 AND 2) AS low
    FROM public.delivery_cohort_2017 c
    CROSS JOIN LATERAL (
        VALUES ('overall', true), ('2017-11 SP', c.purchase_month = date '2017-11-01' AND c.customer_state = 'SP')
    ) slice(name, included)
    WHERE slice.included
    GROUP BY slice.name
), expected(name, eligible, on_time, rated, low) AS (
    VALUES ('overall', 43426, 40973, 43079, 5211), ('2017-11 SP', 2898, 2696, 2879, 350)
)
SELECT count(*) = 2 AND bool_and((c.eligible, c.on_time, c.rated, c.low)
    IS NOT DISTINCT FROM (e.eligible, e.on_time, e.rated, e.low)) AS passed
FROM expected e FULL JOIN checks c USING (name)
\gset
\if :passed
    \echo Delivery metric reconciliation checks passed.
\else
    DO $$ BEGIN RAISE EXCEPTION 'Delivery metric reconciliation failed'; END $$;
\endif
