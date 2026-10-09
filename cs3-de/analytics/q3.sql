-- Customers and customer categories contribute the most revenue

SELECT
    c.customer_id,
    c.customer_name,
    c.category_name AS customer_category,
    c.buying_group_name,
    COUNT(DISTINCT s.invoice_id) AS total_invoices,
    SUM(s.extended_price_excl_tax) AS total_revenue,
    SUM(s.line_profit) AS total_profit
FROM olap.fact_sale s
JOIN olap.dim_customer c ON s.customer_sk = c.customer_sk
GROUP BY
    c.customer_id,
    c.customer_name,
    c.category_name,
    c.buying_group_name
ORDER BY
    total_revenue DESC
LIMIT 50;
