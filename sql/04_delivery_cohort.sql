CREATE OR REPLACE VIEW public.delivery_cohort_2017 AS
SELECT
    order_id,
    date_trunc('month', order_purchase_timestamp)::date AS purchase_month,
    customer_state,
    order_category,
    -- Compare calendar dates using the source timestamps as stored.
    order_delivered_customer_date::date - order_estimated_delivery_date::date AS delay_days,
    review_score,
    order_delivered_customer_date,
    -- Each stage has its own denominator. Missing or inverted pairs produce null.
    CASE WHEN order_approved_at >= order_purchase_timestamp
           AND order_approved_at < timestamp '2018-06-01'
        THEN extract(epoch FROM order_approved_at - order_purchase_timestamp) / 3600 END
        AS purchase_to_approval_hours,
    CASE WHEN order_delivered_carrier_date >= order_approved_at
           AND order_delivered_carrier_date < timestamp '2018-06-01'
        THEN extract(epoch FROM order_delivered_carrier_date - order_approved_at) / 3600 END
        AS approval_to_carrier_hours,
    CASE WHEN order_delivered_customer_date >= order_delivered_carrier_date
        THEN extract(epoch FROM order_delivered_customer_date - order_delivered_carrier_date) / 3600 END
        AS carrier_to_delivery_hours
FROM public.order_summary
WHERE order_purchase_timestamp >= timestamp '2017-01-01'
  AND order_purchase_timestamp < timestamp '2018-01-01'
  AND order_status = 'delivered'
  AND order_estimated_delivery_date IS NOT NULL
  AND order_delivered_customer_date >= order_purchase_timestamp
  AND order_delivered_customer_date < timestamp '2018-06-01';
