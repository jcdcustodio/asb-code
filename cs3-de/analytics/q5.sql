-- Employees or salespeople managing the highest-value orders and sales

WITH rep_orders AS (
    SELECT
        salesperson_sk,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(extended_price_excl_tax) AS total_ordered_value,
        ROUND(AVG(extended_price_excl_tax), 2) AS avg_order_line_value
    FROM olap.fact_order
    GROUP BY salesperson_sk
),
rep_sales AS (
    SELECT
        salesperson_sk,
        COUNT(DISTINCT invoice_id) AS total_invoices,
        SUM(extended_price_excl_tax) AS total_invoiced_sales,
        SUM(line_profit) AS total_profit
    FROM olap.fact_sale
    GROUP BY salesperson_sk
)
SELECT
    e.employee_id,
    e.full_name AS salesperson_name,
    COALESCE(ro.total_orders, 0) AS total_orders_managed,
    COALESCE(ro.total_ordered_value, 0) AS total_ordered_value,
    COALESCE(rs.total_invoices, 0) AS total_invoices_managed,
    COALESCE(rs.total_invoiced_sales, 0) AS total_invoiced_sales,
    COALESCE(rs.total_profit, 0) AS total_profit_generated
FROM olap.dim_employee e
LEFT JOIN rep_orders ro ON e.employee_sk = ro.salesperson_sk
LEFT JOIN rep_sales rs  ON e.employee_sk = rs.salesperson_sk
WHERE e.is_salesperson = TRUE 
    OR ro.salesperson_sk IS NOT NULL
ORDER BY
    total_invoiced_sales DESC;
