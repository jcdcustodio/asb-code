-- Generate calendar from 2012 to 2026
INSERT INTO olap.dim_date (
    date_key,
    full_date,
    day_of_month,
    day_of_week,
    day_name,
    calendar_month,
    calendar_month_name,
    calendar_quarter,
    calendar_year,
    fiscal_month,
    fiscal_quarter,
    fiscal_year,
    is_weekend
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT AS date_key,
    d::DATE AS full_date,
    EXTRACT(DAY FROM d)::INT AS day_of_month,
    EXTRACT(ISODOW FROM d)::INT AS day_of_week,
    -- FM prefix suppresses trailing whitespace padding
    TO_CHAR(d, 'FMDay') AS day_name,
    EXTRACT(MONTH FROM d)::INT AS calendar_month,
    TO_CHAR(d, 'FMMonth') AS calendar_month_name,
    EXTRACT(QUARTER FROM d)::INT AS calendar_quarter,
    EXTRACT(YEAR FROM d)::INT AS calendar_year,
    -- Fiscal calculations (starts November 1)
    CASE 
        WHEN EXTRACT(MONTH FROM d) >= 11 
        THEN EXTRACT(MONTH FROM d)::INT - 10
        ELSE EXTRACT(MONTH FROM d)::INT + 2
    END AS fiscal_month,
    CASE 
        WHEN EXTRACT(MONTH FROM d) IN (11, 12, 1) THEN 1
        WHEN EXTRACT(MONTH FROM d) IN (2, 3, 4) THEN 2
        WHEN EXTRACT(MONTH FROM d) IN (5, 6, 7) THEN 3
        ELSE 4
    END AS fiscal_quarter,
    CASE 
        WHEN EXTRACT(MONTH FROM d) >= 11 
        THEN EXTRACT(YEAR FROM d)::INT + 1
        ELSE EXTRACT(YEAR FROM d)::INT
    END AS fiscal_year,
    CASE 
        WHEN EXTRACT(ISODOW FROM d) IN (6, 7) 
        THEN TRUE 
        ELSE FALSE 
    END AS is_weekend
FROM GENERATE_SERIES('2012-01-01'::DATE, '2026-12-31'::DATE, '1 day'::INTERVAL) d
ON CONFLICT (date_key) DO NOTHING;
