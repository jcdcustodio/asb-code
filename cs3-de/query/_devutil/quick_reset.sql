TRUNCATE TABLE 
    olap.fact_order,
    olap.fact_sale,
    olap.dim_city,
    olap.dim_customer,
    olap.dim_date,
    olap.dim_employee,
    olap.dim_stock_item
CASCADE;

DROP SCHEMA IF EXISTS oltp CASCADE;
DROP SCHEMA IF EXISTS olap CASCADE;
