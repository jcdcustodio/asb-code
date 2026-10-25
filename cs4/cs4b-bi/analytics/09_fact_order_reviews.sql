CREATE OR REPLACE VIEW analytics.fact_order_reviews AS
SELECT 
    review_id,
    order_id,
    review_score,
    review_creation_date::TIMESTAMP AS review_creation_timestamp,
    review_answer_timestamp::TIMESTAMP AS review_answer_timestamp
FROM kaggle.olist_order_reviews_dataset;