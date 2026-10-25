CREATE OR REPLACE VIEW analytics.fact_order_items AS
SELECT 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date::TIMESTAMP AS shipping_limit_timestamp,
    price::NUMERIC(10, 2) AS price,
    freight_value::NUMERIC(10, 2) AS freight_value,
    (price + freight_value)::NUMERIC(10, 2) AS gross_item_revenue
FROM kaggle.olist_order_items_dataset;