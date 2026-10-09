-- Orders containing backordered items and their business impact

-- High-level business impact comparison
SELECT
    fo.is_undersupply_backordered,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    SUM(fo.ordered_quantity) AS total_units,
    SUM(fo.extended_price_excl_tax) AS total_value_excl_tax,
    ROUND(
        AVG(fo.extended_price_excl_tax), 2
    ) AS avg_line_value
FROM olap.fact_order fo
GROUP BY fo.is_undersupply_backordered;

-- Granular order lines impacted by backorders
SELECT
    fo.order_id,
    d.full_date AS order_date,
    c.customer_name,
    si.stock_item_name,
    fo.ordered_quantity,
    fo.extended_price_excl_tax AS delayed_revenue_impact
FROM olap.fact_order fo
JOIN olap.dim_date d ON fo.order_date_key = d.date_key
JOIN olap.dim_customer c ON fo.customer_sk = c.customer_sk
JOIN olap.dim_stock_item si ON fo.stock_item_sk = si.stock_item_sk
WHERE fo.is_undersupply_backordered = TRUE
ORDER BY fo.extended_price_excl_tax DESC
LIMIT 50;
