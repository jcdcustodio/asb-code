-- Average duration for an order to be invoiced

SELECT
    d.calendar_year,
    d.calendar_month,
    d.calendar_month_name,
    COUNT(DISTINCT s.invoice_id) AS invoices_count,
    ROUND(AVG(s.days_order_to_invoice), 2) AS avg_days_to_invoice,
    MIN(s.days_order_to_invoice) AS min_days_to_invoice,
    MAX(s.days_order_to_invoice) AS max_days_to_invoice
FROM olap.fact_sale s
JOIN olap.dim_date d ON s.invoice_date_key = d.date_key
WHERE s.days_order_to_invoice IS NOT NULL
GROUP BY
    d.calendar_year,
    d.calendar_month,
    d.calendar_month_name
ORDER BY
    d.calendar_year,
    d.calendar_month;
