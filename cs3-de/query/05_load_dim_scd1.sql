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
WHERE NOT EXISTS (
    SELECT 1 FROM olap.dim_city dc WHERE dc.city_id = ci.city_id
);

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
WHERE NOT EXISTS (
    SELECT 1 FROM olap.dim_stock_item dsi WHERE dsi.stock_item_id = si.stock_item_id
);

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
WHERE p.is_employee = TRUE 
    OR p.is_salesperson = TRUE
    OR p.person_id IN (
        SELECT DISTINCT salesperson_person_id FROM oltp.orders
    )
ON CONFLICT (employee_sk) DO NOTHING;
