-- Proportion of invoiced ordered quantities

WITH order_totals AS (
    SELECT
        order_id,
        SUM(ordered_quantity) AS total_ordered_qty
    FROM olap.fact_order
    GROUP BY order_id
),
invoice_totals AS (
    SELECT
        order_id,
        SUM(invoiced_quantity) AS total_invoiced_qty
    FROM olap.fact_sale
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)
SELECT
    SUM(o.total_ordered_qty) AS global_ordered_qty,
    SUM(COALESCE(i.total_invoiced_qty, 0)) AS global_invoiced_qty,
    ROUND(
        (SUM(COALESCE(i.total_invoiced_qty, 0))::NUMERIC / NULLIF(SUM(o.total_ordered_qty), 0)) * 100.0, 2
    ) AS invoiced_percentage,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(
        DISTINCT CASE 
            WHEN COALESCE(i.total_invoiced_qty, 0) >= o.total_ordered_qty 
            THEN o.order_id 
        END
    ) AS fully_invoiced_orders
FROM order_totals o
LEFT JOIN invoice_totals i ON o.order_id = i.order_id;
