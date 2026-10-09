-- Products and product categories generate the highest sales and profit

SELECT
    COALESCE(si.brand, 'Unbranded') AS product_category,
    si.stock_item_id,
    si.stock_item_name,
    SUM(s.invoiced_quantity) AS total_units_sold,
    SUM(s.extended_price_excl_tax) AS total_sales,
    SUM(s.line_profit) AS total_profit,
    ROUND(
        (SUM(s.line_profit) / NULLIF(SUM(s.extended_price_excl_tax), 0)) * 100.0, 2
    ) AS profit_margin_pct
FROM olap.fact_sale s
JOIN olap.dim_stock_item si 
    ON s.stock_item_sk = si.stock_item_sk
GROUP BY
    si.brand,
    si.stock_item_id,
    si.stock_item_name
ORDER BY
    total_sales DESC
LIMIT 50;
