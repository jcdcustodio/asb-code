CREATE SCHEMA IF NOT EXISTS olap;

-- Date Dimension
CREATE TABLE IF NOT EXISTS olap.dim_date (
    date_key INT PRIMARY KEY,   -- YYYYMMDD
    full_date DATE NOT NULL,
    day_of_month INT NOT NULL,
    day_name TEXT NOT NULL,
    calendar_month INT NOT NULL,
    calendar_month_name TEXT NOT NULL,
    calendar_quarter INT NOT NULL,
    calendar_year INT NOT NULL,
    fiscal_month INT NOT NULL,
    fiscal_quarter INT NOT NULL,
    fiscal_year INT NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

-- Geography Dimension
CREATE TABLE IF NOT EXISTS olap.dim_city (
    city_sk SERIAL PRIMARY KEY,
    city_id INT NOT NULL,
    city_name TEXT NOT NULL,
    state_province_code TEXT NOT NULL,
    state_province_name TEXT NOT NULL,
    country_name TEXT NOT NULL,
    sales_territory TEXT
);

-- Customer Dimension (SCD Type 2)
CREATE TABLE IF NOT EXISTS olap.dim_customer (
    customer_sk SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,   -- Natural Key
    customer_name TEXT NOT NULL,
    category_name TEXT NOT NULL,
    buying_group_name TEXT,
    delivery_city_name TEXT,
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
    valid_to TIMESTAMP WITH TIME ZONE NOT NULL,
    is_current BOOLEAN NOT NULL
);

-- Stock Item Dimension (SCD Type 1 for simplicity)
CREATE TABLE IF NOT EXISTS olap.dim_stock_item (
    stock_item_sk SERIAL PRIMARY KEY,
    stock_item_id INT NOT NULL,
    stock_item_name TEXT NOT NULL,
    brand TEXT,
    color_name TEXT,
    package_type_name TEXT,
    unit_price NUMERIC(18, 2),
    tax_rate NUMERIC(18, 3)
);

-- Employee Dimension
CREATE TABLE IF NOT EXISTS olap.dim_employee (
    employee_sk SERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    full_name TEXT NOT NULL,
    is_salesperson BOOLEAN
);

-- Fact Order
CREATE TABLE IF NOT EXISTS olap.fact_order (
    order_line_sk SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    order_line_id INT NOT NULL,
    order_date_key INT REFERENCES olap.dim_date(date_key),
    customer_sk INT REFERENCES olap.dim_customer(customer_sk),
    stock_item_sk INT REFERENCES olap.dim_stock_item(stock_item_sk),
    salesperson_sk INT REFERENCES olap.dim_employee(employee_sk),
    ordered_quantity INT NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    tax_rate NUMERIC(18, 3) NOT NULL,
    tax_amount NUMERIC(18, 2),
    extended_price_excl_tax NUMERIC(18, 2),
    extended_price_incl_tax NUMERIC(18, 2)
);

-- Fact Sale (Invoice Line Grain)
CREATE TABLE IF NOT EXISTS olap.fact_sale (
    sale_line_sk SERIAL PRIMARY KEY,
    invoice_id INT NOT NULL,
    invoice_line_id INT NOT NULL,
    invoice_date_key INT REFERENCES olap.dim_date(date_key),
    customer_sk INT REFERENCES olap.dim_customer(customer_sk),
    stock_item_sk INT REFERENCES olap.dim_stock_item(stock_item_sk),
    salesperson_sk INT REFERENCES olap.dim_employee(employee_sk),
    invoiced_quantity INT NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    tax_rate NUMERIC(18, 3) NOT NULL,
    tax_amount NUMERIC(18, 2),
    extended_price_excl_tax NUMERIC(18, 2),
    extended_price_incl_tax NUMERIC(18, 2),
    line_profit NUMERIC(18, 2),
    days_order_to_invoice INT
);
