CREATE OR REPLACE VIEW analytics.dim_customers AS
WITH customer_frequency AS (
    SELECT 
        customer_unique_id,
        COUNT(order_id) AS lifetime_orders_count
    FROM kaggle.olist_customers_dataset c
    JOIN kaggle.olist_orders_dataset o 
        ON c.customer_id = o.customer_id
    GROUP BY customer_unique_id
)
SELECT 
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix AS zip_code_prefix,
    c.customer_city AS city,
    c.customer_state AS state,
    g.latitude,
    g.longitude,
    cf.lifetime_orders_count,
    CASE 
        WHEN cf.lifetime_orders_count > 1 THEN 'Repeat' 
        ELSE 'One-Time' 
    END AS customer_type
FROM kaggle.olist_customers_dataset c
LEFT JOIN analytics.dim_geolocation g 
    ON c.customer_zip_code_prefix = g.zip_code_prefix
LEFT JOIN customer_frequency cf 
    ON c.customer_unique_id = cf.customer_unique_id;