-- Dim City: Flattens cities, state_provinces, and countries
INSERT INTO olap.dim_city (
    city_id,
    city_name,
    state_province_code,
    state_province_name,
    country_name,
    sales_territory
)
SELECT 
    ci.city_id,
    ci.city_name,
    sp.state_province_code,
    sp.state_province_name,
    co.country_name,
    COALESCE(sp.sales_territory, 'Undetermined')
FROM oltp.cities ci
JOIN oltp.state_provinces sp ON ci.state_province_id = sp.state_province_id
JOIN oltp.countries co ON sp.country_id = co.country_id
ON CONFLICT (city_id) DO UPDATE SET
    city_name           = EXCLUDED.city_name,
    state_province_code = EXCLUDED.state_province_code,
    state_province_name = EXCLUDED.state_province_name,
    country_name        = EXCLUDED.country_name,
    sales_territory     = EXCLUDED.sales_territory;

-- Dim Stock Item: Flattens stock_items, colors, and package_types
INSERT INTO olap.dim_stock_item (
    stock_item_id,
    stock_item_name,
    brand,
    color_name,
    package_type_name,
    unit_price,
    tax_rate
)
SELECT 
    si.stock_item_id,
    si.stock_item_name,
    COALESCE(si.brand, 'Unbranded'),
    COALESCE(c.color_name, 'No Color'),
    COALESCE(pt.package_type_name, 'None'),
    si.unit_price,
    si.tax_rate
FROM oltp.stock_items si
LEFT JOIN oltp.colors c ON si.color_id = c.color_id
LEFT JOIN oltp.package_types pt ON si.unit_package_id = pt.package_type_id
ON CONFLICT (stock_item_id) DO UPDATE SET
    stock_item_name = EXCLUDED.stock_item_name,
    brand = EXCLUDED.brand,
    color_name = EXCLUDED.color_name,
    package_type_name = EXCLUDED.package_type_name,
    unit_price = EXCLUDED.unit_price,
    tax_rate = EXCLUDED.tax_rate;

-- Dim Employee: Filters active employees and sales personnel
INSERT INTO olap.dim_employee (
    employee_id,
    full_name,
    is_salesperson
)
SELECT 
    p.person_id,
    p.full_name,
    COALESCE(p.is_salesperson, FALSE)
FROM oltp.people p
WHERE (
    p.is_employee = TRUE 
    OR p.is_salesperson = TRUE
    OR p.person_id IN (
        SELECT DISTINCT salesperson_person_id 
        FROM oltp.orders 
        WHERE salesperson_person_id IS NOT NULL
    )
    OR p.person_id IN (
        SELECT DISTINCT salesperson_person_id 
        FROM oltp.invoices 
        WHERE salesperson_person_id IS NOT NULL
    )
)
ON CONFLICT (employee_id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    is_salesperson = EXCLUDED.is_salesperson;