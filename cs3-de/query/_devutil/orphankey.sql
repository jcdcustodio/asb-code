SELECT 
    'fact_order orphans' AS scope,
    COUNT(*) AS total_orphans,
    -- Is order_date completely NULL (e.g., ingestion format parsing failure)?
    COUNT(*) FILTER (WHERE o.order_date IS NULL) AS null_order_dates,
    -- Does the customer_id even exist in dim_customer?
    COUNT(*) FILTER (WHERE dc.customer_id IS NULL) AS missing_natural_key,
    -- Does customer exist, but order_date is before valid_from?
    COUNT(*) FILTER (WHERE dc.customer_id IS NOT NULL AND o.order_date < dc.valid_from::DATE) AS order_predates_valid_from,
    -- Does customer exist, but order_date is after valid_to?
    COUNT(*) FILTER (WHERE dc.customer_id IS NOT NULL AND o.order_date > dc.valid_to::DATE) AS order_postdates_valid_to
FROM oltp.orders o
JOIN oltp.order_lines ol ON o.order_id = ol.order_id
LEFT JOIN olap.dim_customer dc ON o.customer_id = dc.customer_id AND dc.customer_sk > 0
LEFT JOIN olap.fact_order fo ON ol.order_line_id = fo.order_line_id
WHERE fo.customer_sk = 0;

SELECT COUNT(*) FROM oltp.orders WHERE order_date IS NULL;
