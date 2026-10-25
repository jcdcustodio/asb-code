CREATE OR REPLACE VIEW analytics.dim_geolocation AS
SELECT 
    geolocation_zip_code_prefix AS zip_code_prefix,
    MAX(geolocation_city) AS city,
    MAX(geolocation_state) AS state,
    AVG(geolocation_lat) AS latitude,
    AVG(geolocation_lng) AS longitude
FROM kaggle.olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix;