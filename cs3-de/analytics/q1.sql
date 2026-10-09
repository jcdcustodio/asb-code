-- Total sales, quantity sold, and profit by month and fiscal year

SELECT
	d.fiscal_year,
	d.calendar_year,
	d.calendar_month,
	d.calendar_month_name,
	SUM(s.invoiced_quantity) AS total_quantity_sold,
	SUM(s.extended_price_excl_tax) AS total_sales_excl_tax,
	SUM(s.line_profit) AS total_profit
FROM olap.fact_sale s
JOIN olap.dim_date d ON s.invoice_date_key = d.date_key
GROUP BY
	d.fiscal_year,
	d.calendar_year,
	d.calendar_month,
	d.calendar_month_name
ORDER BY
	d.fiscal_year,
	d.calendar_month;
