SELECT 
    customer_sk,
    customer_id,
    customer_name,
    category_name,
    delivery_city_name,
    valid_from,
    valid_to,
    is_current
FROM olap.dim_customer
WHERE customer_id = 893;

SELECT 
    fo.order_id,
    fo.order_date_key,
    fo.customer_sk,
    fo.city_sk,
    dc.customer_name,
    dc.category_name,
    ci.city_name,
    dc.is_current
FROM olap.fact_order fo
JOIN olap.dim_customer dc ON fo.customer_sk = dc.customer_sk
JOIN olap.dim_city ci ON fo.city_sk = ci.city_sk
WHERE dc.customer_id = 893
LIMIT 5;