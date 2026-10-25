CREATE OR REPLACE VIEW analytics.fact_order_payments AS
SELECT 
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value::NUMERIC(10, 2) AS payment_value
FROM kaggle.olist_order_payments_dataset;