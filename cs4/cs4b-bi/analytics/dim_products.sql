CREATE OR REPLACE VIEW analytics.dim_products AS
SELECT 
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS product_category,
    p.product_name_lenght AS product_name_length,
    p.product_description_lenght AS product_description_length,
    p.product_photos_qty AS product_photos_quantity,
    p.product_weight_g AS product_weight_grams,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM kaggle.olist_products_dataset p
LEFT JOIN kaggle.product_category_name_translation t
    ON p.product_category_name = t.product_category_name;