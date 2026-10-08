CREATE SCHEMA IF NOT EXISTS oltp;

CREATE TABLE IF NOT EXISTS oltp._ingestion_metadata (
    ingest_id SERIAL PRIMARY KEY,
    source_file TEXT NOT NULL,
    records_loaded INT NOT NULL,
    loaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status TEXT NOT NULL
);

-- Core Reference Tables
CREATE TABLE IF NOT EXISTS oltp.countries (
    country_id INT PRIMARY KEY,
    country_name TEXT NOT NULL,
    formal_name TEXT NOT NULL,
    latest_recorded_population INT,
    continent TEXT,
    region TEXT,
    subregion TEXT
);

CREATE TABLE IF NOT EXISTS oltp.state_provinces (
    state_province_id INT PRIMARY KEY,
    state_province_code TEXT NOT NULL,
    state_province_name TEXT NOT NULL,
    country_id INT REFERENCES oltp.countries(country_id),
    sales_territory TEXT,
    latest_recorded_population INT
);

CREATE TABLE IF NOT EXISTS oltp.cities (
    city_id INT PRIMARY KEY,
    city_name TEXT NOT NULL,
    state_province_id INT REFERENCES oltp.state_provinces(state_province_id),
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    latest_recorded_population INT
);

CREATE TABLE IF NOT EXISTS oltp.customer_categories (
    customer_category_id INT PRIMARY KEY,
    customer_category_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.buying_groups (
    buying_group_id INT PRIMARY KEY,
    buying_group_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.customers (
    customer_id INT PRIMARY KEY,
    customer_name TEXT NOT NULL,
    bill_to_customer_id INT NOT NULL,
    customer_category_id INT REFERENCES oltp.customer_categories(customer_category_id),
    buying_group_id INT REFERENCES oltp.buying_groups(buying_group_id),
    primary_contact_person_id INT NOT NULL,
    alternate_contact_person_id INT,
    delivery_method_id INT,
    delivery_city_id INT REFERENCES oltp.cities(city_id),
    credit_limit NUMERIC(18, 2),
    account_opened_date DATE,
    standard_discount_percentage NUMERIC(18, 2),
    is_statement_sent BOOLEAN,
    is_on_credit_hold BOOLEAN,
    payment_days INT,
    phone_number TEXT,
    website_url TEXT,
    delivery_address_line TEXT,
    delivery_location_lat NUMERIC(10, 7),
    delivery_location_long NUMERIC(10, 7)
);

CREATE TABLE IF NOT EXISTS oltp.people (
    person_id INT PRIMARY KEY,
    full_name TEXT NOT NULL,
    preferred_name TEXT,
    search_name TEXT,
    is_employee BOOLEAN,
    is_salesperson BOOLEAN
);

CREATE TABLE IF NOT EXISTS oltp.colors (
    color_id INT PRIMARY KEY,
    color_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.package_types (
    package_type_id INT PRIMARY KEY,
    package_type_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.stock_items (
    stock_item_id INT PRIMARY KEY,
    stock_item_name TEXT NOT NULL,
    supplier_id INT,
    color_id INT REFERENCES oltp.colors(color_id),
    unit_package_id INT REFERENCES oltp.package_types(package_type_id),
    outer_package_id INT,
    brand TEXT,
    size TEXT,
    lead_time_days INT,
    quantity_per_outer INT,
    is_chiller_stock BOOLEAN,
    barcode TEXT,
    tax_rate NUMERIC(18, 3) NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    recommended_retail_price NUMERIC(18, 2),
    typical_weight_per_unit NUMERIC(18, 2)
);

-- Transaction Tables (With NOT NULL constraints and consistent FKs)
CREATE TABLE IF NOT EXISTS oltp.orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES oltp.customers(customer_id),
    salesperson_person_id INT REFERENCES oltp.people(person_id),
    picked_by_person_id INT,
    contact_person_id INT,
    backorder_order_id INT,
    order_date DATE NOT NULL,
    expected_delivery_date DATE,
    customer_purchase_order_number INT,
    is_undersupply_backordered BOOLEAN,
    picking_completed_when TIMESTAMP
);

CREATE TABLE IF NOT EXISTS oltp.order_lines (
    order_line_id INT PRIMARY KEY,
    order_id INT REFERENCES oltp.orders(order_id),
    stock_item_id INT REFERENCES oltp.stock_items(stock_item_id),
    description TEXT,
    package_type_id INT REFERENCES oltp.package_types(package_type_id),
    quantity INT NOT NULL,
    unit_price NUMERIC(18, 2),
    tax_rate NUMERIC(18, 3),
    picked_quantity INT,
    picking_completed_when TIMESTAMP
);

CREATE TABLE IF NOT EXISTS oltp.invoices (
    invoice_id INT PRIMARY KEY,
    customer_id INT REFERENCES oltp.customers(customer_id),
    bill_to_customer_id INT,
    order_id INT REFERENCES oltp.orders(order_id),
    delivery_method_id INT,
    contact_person_id INT,
    accounts_person_id INT,
    salesperson_person_id INT REFERENCES oltp.people(person_id),
    packed_by_person_id INT,
    invoice_date DATE NOT NULL,
    customer_purchase_order_number INT,
    delivery_instructions TEXT,
    total_dry_items INT,
    total_chiller_items INT,
    confirmed_delivery_time TIMESTAMP,
    confirmed_received_by TEXT
);

CREATE TABLE IF NOT EXISTS oltp.invoice_lines (
    invoice_line_id INT PRIMARY KEY,
    invoice_id INT REFERENCES oltp.invoices(invoice_id),
    stock_item_id INT REFERENCES oltp.stock_items(stock_item_id),
    description TEXT,
    package_type_id INT REFERENCES oltp.package_types(package_type_id),
    quantity INT NOT NULL,
    unit_price NUMERIC(18, 2),
    tax_rate NUMERIC(18, 3),
    tax_amount NUMERIC(18, 2),
    line_profit NUMERIC(18, 2),
    extended_price NUMERIC(18, 2)
);
