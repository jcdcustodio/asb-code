-- Dimension attributes associated with transactions before and after an SCD change

SELECT
    s.invoice_id,
    d.full_date AS transaction_date,
    s.customer_sk AS assigned_surrogate_key,
    c.customer_id,
    c.customer_name,
    c.category_name AS dimension_category_at_sale_time,
    c.delivery_city_name AS delivery_city_at_sale_time,
    c.valid_from AS version_valid_from,
    c.valid_to AS version_valid_to,
    c.is_current AS is_currently_active_version,
    s.extended_price_excl_tax AS invoiced_amount
FROM olap.fact_sale s
JOIN olap.dim_customer c ON s.customer_sk = c.customer_sk
JOIN olap.dim_date d ON s.invoice_date_key = d.date_key
-- Substitute with any SCD-tracked customer ID
WHERE c.customer_id = 893 
ORDER BY
    d.full_date
LIMIT 50;
