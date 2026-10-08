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

--

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

--

SELECT 
    'fact_order' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_sk = 0) AS orphan_customer_sk,
    COUNT(*) FILTER (WHERE stock_item_sk = 0) AS orphan_stock_item_sk,
    COUNT(*) FILTER (WHERE salesperson_sk = 0) AS orphan_salesperson_sk
FROM olap.fact_order
UNION ALL
SELECT 
    'fact_sale' AS table_name,
    COUNT(*),
    COUNT(*) FILTER (WHERE customer_sk = 0),
    COUNT(*) FILTER (WHERE stock_item_sk = 0),
    COUNT(*) FILTER (WHERE salesperson_sk = 0)
FROM olap.fact_sale;

-- Check the valid_from timestamps currently sitting in your customer dimension
SELECT 
    COUNT(*) AS total_customers,
    MIN(valid_from) AS min_valid_from,
    MAX(valid_from) AS max_valid_from,
    COUNT(*) FILTER (WHERE valid_from >= '2020-01-01') AS count_invalid_current_timestamp
FROM olap.dim_customer
WHERE customer_sk > 0;