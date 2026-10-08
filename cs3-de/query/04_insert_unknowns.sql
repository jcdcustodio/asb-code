-- Insert surrogate key 0 for all dimensional entities
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

INSERT INTO olap.dim_employee (
    employee_sk, 
    employee_id, 
    full_name, 
    is_salesperson
)
VALUES (0, 0, 'Unknown Employee', FALSE)
ON CONFLICT (employee_sk) DO NOTHING;

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
    '1900-01-01 00:00:00+00', 
    '9999-12-31 23:59:59+00', 
    TRUE
)
ON CONFLICT (customer_sk) DO NOTHING;
