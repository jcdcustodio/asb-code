INSERT INTO oltp.orders (
    order_id, 
    customer_id, 
    salesperson_person_id, 
    order_date, 
    expected_delivery_date, 
    is_undersupply_backordered
) 
VALUES (
    999999, 
    893, 
    2, 
    CURRENT_DATE, 
    CURRENT_DATE, 
    FALSE
);

INSERT INTO oltp.order_lines (
    order_line_id, 
    order_id, 
    stock_item_id, 
    package_type_id, 
    quantity, 
    unit_price, 
    tax_rate
) 
VALUES (
    999999, 
    999999, 
    1, 
    1, 
    25, 
    120.00, 
    15.000
);

-- Verify resolution after reloading fact tables
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
WHERE fo.order_id = 999999;
