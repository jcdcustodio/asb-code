CREATE OR REPLACE VIEW analytics.dim_sellers AS
SELECT 
    s.seller_id,
    s.seller_zip_code_prefix AS zip_code_prefix,
    s.seller_city AS city,
    s.seller_state AS state,
    g.latitude,
    g.longitude
FROM kaggle.olist_sellers_dataset s
LEFT JOIN analytics.dim_geolocation g 
    ON s.seller_zip_code_prefix = g.zip_code_prefix;