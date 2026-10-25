-- If DuckDB: use generate_series(DATE '2016-01-01', DATE '2018-12-31', INTERVAL 1 DAY))

CREATE OR REPLACE VIEW analytics.dim_date AS
SELECT 
    datum::DATE AS date_key,
    EXTRACT(YEAR FROM datum)::INT AS year,
    EXTRACT(QUARTER FROM datum)::INT AS quarter,
    TO_CHAR(datum, 'YYYY-"Q"Q') AS year_quarter,
    EXTRACT(MONTH FROM datum)::INT AS month,
    TO_CHAR(datum, 'YYYY-MM') AS year_month,
    TO_CHAR(datum, 'Month') AS month_name,
    EXTRACT(ISODOW FROM datum)::INT AS day_of_week,
    TO_CHAR(datum, 'Day') AS day_name,
    CASE WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN 1 ELSE 0 END AS is_weekend
FROM generate_series(DATE '2016-01-01', DATE '2018-12-31', INTERVAL '1 day') AS datum;