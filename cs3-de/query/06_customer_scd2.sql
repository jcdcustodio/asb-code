BEGIN;

-- Flatten the current operational state into a temporary table
CREATE TEMP TABLE staging_customer ON COMMIT DROP AS
SELECT 
    c.customer_id,
    c.customer_name,
    COALESCE(cat.customer_category_name, 'Unknown') AS category_name,
    COALESCE(bg.buying_group_name, 'None') AS buying_group_name,
    COALESCE(ci.city_name, 'Unknown') AS delivery_city_name
FROM oltp.customers c
LEFT JOIN oltp.customer_categories cat ON c.customer_category_id = cat.customer_category_id
LEFT JOIN oltp.buying_groups bg ON c.buying_group_id = bg.buying_group_id
LEFT JOIN oltp.cities ci ON c.delivery_city_id = ci.city_id;

-- Expire existing records where any tracked attribute has changed
UPDATE olap.dim_customer target
SET 
    valid_to = CURRENT_TIMESTAMP,
    is_current = FALSE
FROM staging_customer src
WHERE target.customer_id = src.customer_id
    AND target.is_current = TRUE
    AND (
        target.customer_name IS DISTINCT FROM src.customer_name OR
        target.category_name IS DISTINCT FROM src.category_name OR
        target.buying_group_name IS DISTINCT FROM src.buying_group_name OR
        target.delivery_city_name IS DISTINCT FROM src.delivery_city_name
  );

-- Insert new versions for updated records and initial versions for new customers
INSERT INTO olap.dim_customer (
    customer_id, 
    customer_name, 
    category_name, 
    buying_group_name, 
    delivery_city_name, 
    valid_from, 
    valid_to, 
    is_current
)
SELECT 
    src.customer_id,
    src.customer_name,
    src.category_name,
    src.buying_group_name,
    src.delivery_city_name,
    -- If customer existed prior to this batch, it's an SCD2 update -> use CURRENT_TIMESTAMP.
    -- If customer is brand-new (Load 1), use 2012-01-01 to cover all historical orders.
    CASE 
        WHEN target_prev.customer_id IS NOT NULL THEN CURRENT_TIMESTAMP
        ELSE '2012-01-01 00:00:00+00'::TIMESTAMPTZ
    END AS valid_from,
    '9999-12-31 23:59:59+00'::TIMESTAMPTZ AS valid_to,
    TRUE AS is_current
FROM staging_customer src
LEFT JOIN (
    SELECT DISTINCT customer_id 
    FROM olap.dim_customer 
    WHERE customer_sk > 0
) target_prev ON src.customer_id = target_prev.customer_id
LEFT JOIN olap.dim_customer target_active
    ON src.customer_id = target_active.customer_id 
    AND target_active.is_current = TRUE
WHERE target_active.customer_sk IS NULL;

COMMIT;
