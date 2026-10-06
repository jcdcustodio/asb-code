CREATE SCHEMA IF NOT EXISTS olap;

-- 1. Date Dimension
CREATE TABLE IF NOT EXISTS olap.dim_date (
    date_key INT PRIMARY KEY,   -- YYYYMMDD
    full_date DATE NOT NULL,
    day_of_month INT NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    calendar_month INT NOT NULL,
    calendar_month_name VARCHAR(15) NOT NULL,
    calendar_quarter INT NOT NULL,
    calendar_year INT NOT NULL,
    fiscal_month INT NOT NULL,
    fiscal_quarter INT NOT NULL,
    fiscal_year INT NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

-- 2. Geography Dimension
CREATE TABLE IF NOT EXISTS olap.dim_city (
    city_sk SERIAL PRIMARY KEY,
    city_id INT NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    state_province_code VARCHAR(10) NOT NULL,
    state_province_name VARCHAR(100) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    sales_territory VARCHAR(50)
);

-- 3. Customer Dimension (SCD Type 2)
CREATE TABLE IF NOT EXISTS olap.dim_customer (
    customer_sk SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,   -- Natural Key
    customer_name VARCHAR(150) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    buying_group_name VARCHAR(100),
    delivery_city_name VARCHAR(100),
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
    valid_to TIMESTAMP WITH TIME ZONE NOT NULL,
    is_current BOOLEAN NOT NULL
);

-- 4. Stock Item Dimension (SCD Type 1 for simplicity)
CREATE TABLE IF NOT EXISTS olap.dim_stock_item (
    stock_item_sk SERIAL PRIMARY KEY,
    stock_item_id INT NOT NULL,
    stock_item_name VARCHAR(150) NOT NULL,
    brand VARCHAR(50),
    color_name VARCHAR(50),
    package_type_name VARCHAR(50),
    unit_price NUMERIC(18, 2),
    tax_rate NUMERIC(18, 3)
);

-- 5. Employee Dimension
CREATE TABLE IF NOT EXISTS olap.dim_employee (
    employee_sk SERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    is_salesperson BOOLEAN
);

-- 6. Fact Order
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

-- 7. Fact Sale (Invoice Line Grain)
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
