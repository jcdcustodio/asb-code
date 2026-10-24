CREATE OR REPLACE VIEW analytics.fact_orders AS
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp::TIMESTAMP AS purchase_timestamp,
    (order_purchase_timestamp::TIMESTAMP)::DATE AS purchase_date_key,
    order_approved_at::TIMESTAMP AS approved_timestamp,
    order_delivered_carrier_date::TIMESTAMP AS carrier_delivered_timestamp,
    order_delivered_customer_date::TIMESTAMP AS customer_delivered_timestamp,
    order_estimated_delivery_date::TIMESTAMP AS estimated_delivery_timestamp,
    CASE 
        WHEN order_status = 'delivered' THEN 1 
        ELSE 0 
    END AS is_delivered,
    -- Logistics lead time calculations (days)
    CASE 
        WHEN order_delivered_customer_date IS NOT NULL 
        THEN ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date::TIMESTAMP - order_purchase_timestamp::TIMESTAMP)) / 86400.0, 2)
        ELSE NULL 
    END AS delivery_duration_days,
    -- Estimated SLA lead time (days)
    ROUND(EXTRACT(EPOCH FROM (order_estimated_delivery_date::TIMESTAMP - order_purchase_timestamp::TIMESTAMP)) / 86400.0, 2) AS estimated_delivery_duration_days,
    -- SLA breach tag
    CASE 
        WHEN order_delivered_customer_date::TIMESTAMP > order_estimated_delivery_date::TIMESTAMP THEN 1 
        ELSE 0 
    END AS is_late_delivery
FROM kaggle.olist_orders_dataset;