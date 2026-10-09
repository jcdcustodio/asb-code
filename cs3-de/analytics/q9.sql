-- Tracking customer attribute changes over time

SELECT
    customer_id,
    customer_sk,
    customer_name,
    category_name,
    buying_group_name,
    delivery_city_name,
    valid_from,
    valid_to,
    is_current,
    LAG(category_name) OVER (
        PARTITION BY customer_id 
        ORDER BY valid_from
    ) AS previous_category,
    LAG(delivery_city_name) OVER (
        PARTITION BY customer_id 
        ORDER BY valid_from
    ) AS previous_delivery_city
FROM olap.dim_customer
WHERE customer_id IN (
    SELECT customer_id
    FROM olap.dim_customer
    GROUP BY customer_id
    HAVING COUNT(*) > 1
)
ORDER BY
    customer_id,
    valid_from;
