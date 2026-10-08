-- Insert surrogate key 0 for all dimensional entities

-- Date dimension
-- Protects fact_order and fact_sale foreign keys if transaction dates are missing
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
VALUES (
    0,
    '1900-01-01'::DATE,
    1,
    1,
    'Unknown',
    0,
    'Unknown',
    0,
    1900,
    0,
    0,
    1900,
    FALSE
)
ON CONFLICT (date_key) DO NOTHING;

-- Geography dimension
INSERT INTO olap.dim_city (
    city_sk, 
    city_id, 
    city_name, 
    state_province_code, 
    state_province_name, 
    country_name, 
    sales_territory
)
VALUES (
    0,
    0,
    'Unknown City', 
    'N/A',
    'Unknown State', 
    'Unknown Country', 
    'Unknown Territory'
)
ON CONFLICT (city_sk) DO NOTHING;

-- Employee dimension
INSERT INTO olap.dim_employee (
    employee_sk, 
    employee_id, 
    full_name, 
    is_salesperson
)
VALUES (
    0, 
    0, 
    'Unknown Employee', 
    FALSE
)
ON CONFLICT (employee_sk) DO NOTHING;

-- Stock item dimension
INSERT INTO olap.dim_stock_item (
    stock_item_sk, 
    stock_item_id, 
    stock_item_name, 
    brand, 
    color_name, 
    package_type_name, 
    unit_price, 
    tax_rate
)
VALUES (
    0, 
    0, 
    'Unknown Stock Item', 
    'N/A', 
    'N/A', 
    'N/A', 
    0.00, 
    0.000
)
ON CONFLICT (stock_item_sk) DO NOTHING;

-- Customer dimension (SCD2)
-- valid_from is anchored to 1900 to ensure point-in-time joins resolve for any missing key
INSERT INTO olap.dim_customer (
    customer_sk, 
    customer_id, 
    customer_name, 
    category_name, 
    buying_group_name, 
    delivery_city_name, 
    valid_from, 
    valid_to, 
    is_current
)
VALUES (
    0, 
    0, 
    'Unknown Customer', 
    'Unknown', 
    'None', 
    'Unknown', 
    '1900-01-01 00:00:00+00'::TIMESTAMPTZ, 
    '9999-12-31 23:59:59+00'::TIMESTAMPTZ, 
    TRUE
)
ON CONFLICT (customer_sk) DO NOTHING;
