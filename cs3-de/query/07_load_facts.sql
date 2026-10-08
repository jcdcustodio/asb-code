-- Load Fact Orders
-- Grain: 1 row per order line
INSERT INTO olap.fact_order (
    order_id,
    order_line_id,
    order_date_key,
    customer_sk,
    stock_item_sk,
    salesperson_sk,
    ordered_quantity,
    unit_price,
    tax_rate,
    tax_amount,
    extended_price_excl_tax,
    extended_price_incl_tax
)
SELECT 
    o.order_id,
    ol.order_line_id,
    TO_CHAR(o.order_date, 'YYYYMMDD')::INT AS order_date_key,
    COALESCE(c.customer_sk, 0) AS customer_sk,
    COALESCE(s.stock_item_sk, 0) AS stock_item_sk,
    COALESCE(e.employee_sk, 0) AS salesperson_sk,
    ol.quantity AS ordered_quantity,
    ol.unit_price,
    ol.tax_rate,
    ROUND(ol.quantity * ol.unit_price * (ol.tax_rate / 100.0), 2) AS tax_amount,
    ROUND(ol.quantity * ol.unit_price, 2) AS extended_price_excl_tax,
    ROUND(ol.quantity * ol.unit_price * (1 + ol.tax_rate / 100.0), 2) AS extended_price_incl_tax
FROM oltp.orders o
JOIN oltp.order_lines ol ON o.order_id = ol.order_id
-- Point-in-time join to SCD2 customer dim
LEFT JOIN olap.dim_customer c 
    ON o.customer_id = c.customer_id 
   AND o.order_date >= c.valid_from::DATE 
   AND o.order_date <= c.valid_to::DATE
LEFT JOIN olap.dim_stock_item s 
    ON ol.stock_item_id = s.stock_item_id
LEFT JOIN olap.dim_employee e 
    ON o.salesperson_person_id = e.employee_id
WHERE NOT EXISTS (
    SELECT 1 FROM olap.fact_order fo WHERE fo.order_line_id = ol.order_line_id
);

-- Load Fact Sales (Invoiced Transactions)
-- Grain: 1 row per invoice line
INSERT INTO olap.fact_sale (
    invoice_id,
    invoice_line_id,
    invoice_date_key,
    customer_sk,
    stock_item_sk,
    salesperson_sk,
    invoiced_quantity,
    unit_price,
    tax_rate,
    tax_amount,
    extended_price_excl_tax,
    extended_price_incl_tax,
    line_profit,
    days_order_to_invoice
)
SELECT 
    i.invoice_id,
    il.invoice_line_id,
    TO_CHAR(i.invoice_date, 'YYYYMMDD')::INT AS invoice_date_key,
    COALESCE(c.customer_sk, 0) AS customer_sk,
    COALESCE(s.stock_item_sk, 0) AS stock_item_sk,
    COALESCE(e.employee_sk, 0) AS salesperson_sk,
    il.quantity,
    il.unit_price,
    il.tax_rate,
    il.tax_amount,
    il.extended_price AS extended_price_excl_tax,
    ROUND(il.extended_price + il.tax_amount, 2) AS extended_price_incl_tax,
    il.line_profit,
    (i.invoice_date - o.order_date) AS days_order_to_invoice
FROM oltp.invoices i
JOIN oltp.invoice_lines il ON i.invoice_id = il.invoice_id
LEFT JOIN oltp.orders o ON i.order_id = o.order_id
-- Point-in-time join to SCD2 customer dim
LEFT JOIN olap.dim_customer c 
    ON i.customer_id = c.customer_id 
   AND i.invoice_date >= c.valid_from::DATE 
   AND i.invoice_date <= c.valid_to::DATE
LEFT JOIN olap.dim_stock_item s 
    ON il.stock_item_id = s.stock_item_id
LEFT JOIN olap.dim_employee e 
    ON i.salesperson_person_id = e.employee_id
WHERE NOT EXISTS (
    SELECT 1 FROM olap.fact_sale fs WHERE fs.invoice_line_id = il.invoice_line_id
);
