-- Sales and profit variation by city, state or province, and sales territory

SELECT
    ci.sales_territory,
    ci.state_province_name,
    ci.city_name,
    SUM(s.extended_price_excl_tax) AS total_sales,
    SUM(s.line_profit) AS total_profit,
    ROUND(
        (SUM(s.line_profit) / NULLIF(SUM(s.extended_price_excl_tax), 0)) * 100.0, 2
    ) AS profit_margin_pct
FROM olap.fact_sale s
JOIN olap.dim_city ci ON s.city_sk = ci.city_sk
GROUP BY
    ci.sales_territory,
    ci.state_province_name,
    ci.city_name
ORDER BY
    ci.sales_territory,
    total_sales DESC
LIMIT 50;
