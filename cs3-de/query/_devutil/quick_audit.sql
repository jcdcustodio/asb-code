SELECT 
    'dim_city' AS table_name, 
    COUNT(*) AS total_rows, 
    0 AS unresolved_keys 
FROM olap.dim_city
UNION ALL
SELECT 'dim_customer', COUNT(*), 0 FROM olap.dim_customer
UNION ALL
SELECT 'dim_stock_item', COUNT(*), 0 FROM olap.dim_stock_item
UNION ALL
SELECT 'dim_employee', COUNT(*), 0 FROM olap.dim_employee
UNION ALL
SELECT 'dim_date', COUNT(*), 0 FROM olap.dim_date
UNION ALL
SELECT 
    'fact_order', 
    COUNT(*), 
    COUNT(*) FILTER (WHERE customer_sk = 0 OR stock_item_sk = 0 OR salesperson_sk = 0)
FROM olap.fact_order
UNION ALL
SELECT 
    'fact_sale', 
    COUNT(*), 
    COUNT(*) FILTER (WHERE customer_sk = 0 OR stock_item_sk = 0 OR salesperson_sk = 0)
FROM olap.fact_sale;

SELECT 
    customer_sk,
    COUNT(*) AS fact_count
FROM olap.fact_sale
GROUP BY customer_sk
ORDER BY customer_sk ASC
LIMIT 5;

SELECT 
    COUNT(*) AS total_order_lines,
    COUNT(*) FILTER (WHERE customer_sk = 0) AS unresolved_customers,
    COUNT(*) FILTER (WHERE stock_item_sk = 0) AS unresolved_stock_items,
    COUNT(*) FILTER (WHERE salesperson_sk = 0) AS unresolved_salespeople
FROM olap.fact_order;

