TRUNCATE TABLE 
    olap.fact_sale, 
    olap.fact_order, 
    olap.dim_customer, 
    olap.dim_stock_item, 
    olap.dim_employee, 
    olap.dim_city 
CASCADE;

DROP SCHEMA IF EXISTS oltp CASCADE;
DROP SCHEMA IF EXISTS olap CASCADE;
