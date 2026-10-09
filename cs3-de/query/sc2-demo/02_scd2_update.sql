-- From customer_category_id = 3 (Novelty Shop) to 2 (Wholesaler)
-- From delivery_city_id = 36499 (West Elkton) to 19881 (Long Beach)
UPDATE oltp.customers
SET 
    customer_category_id = 2,
    delivery_city_id = 19881
WHERE customer_id = 893;