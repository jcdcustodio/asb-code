# SCD Type 2 Processing Demonstration

### Baseline State

After the initial ingestion and dimensional loading pipeline runs, inspect an active customer from `olap.dim_customer` using `customer_id`. For instance, Customer 893.

```postgresql
SELECT 
    customer_sk,
    customer_id,
    customer_name,
    category_name,
    buying_group_name,
    delivery_city_name,
    valid_from,
    valid_to,
    is_current
FROM olap.dim_customer
WHERE customer_id = 893;
```

> [View result (scd2_p1)](../results/scd2_p1.html)

Note that all historical orders for Customer 893 resolve to `customer_sk = 643`.

```postgresql
SELECT 
    fo.order_id,
    fo.order_date_key,
    fo.customer_sk,
    fo.city_sk,
    dc.customer_name,
    dc.category_name,
    ci.city_name,
    dc.is_current
FROM olap.fact_order fo
JOIN olap.dim_customer dc ON fo.customer_sk = dc.customer_sk
JOIN olap.dim_city ci ON fo.city_sk = ci.city_sk
WHERE dc.customer_id = 893
LIMIT 5;
```

> [View result (scd2_p2)](../results/scd2_p2.html)

Specifically for this demonstration, note their primary delivery location and customer category.

```markdown
customer_category_id = 3 (Novelty Shop)
delivery_city_id = 36499 (West Elkton)
```


### Simulate a change in OLTP

Suppose Customer 893 relocates its primary delivery location from Sylvan Lake to Long Beach and transitions from a novelty shop to a wholesaler.

```markdown
customer_category_id = 2 (Wholesaler)
delivery_city_id = 19881 (Long Beach)
```

```postgresql
UPDATE oltp.customers
SET 
    customer_category_id = 2,
    delivery_city_id = 19881
WHERE customer_id = 893;
```

### Execute the SCD Type 2 transformation

Run the query for staged customer loader in [06_customer_scd2.sql](../query/06_customer_scd2.sql). During execution, the following happens under the hood:

1. `staging_customer` joins `oltp.customers` against `oltp.customer_categories`, `oltp.buying_groups`, and `oltp.cities` to capture the new attributes.
2. The `UPDATE` statement flags that `category_name`, `customer_name`, or `delivery_city_name` has changed (`IS DISTINCT FROM`), sets `valid_to = CURRENT_TIMESTAMP`, and flips `is_current = FALSE` on the existing record (`customer_sk = 643`).
3. The `INSERT` statement sees that Customer 893 already existed, assigns `valid_from = CURRENT_TIMESTAMP` and `valid_to = '9999-12-31 23:59:59+00'`, and inserts a new row with `is_current = TRUE`.

### Verify the customer dimension state

Query all versions of `customer_id = 893` in `olap.dim_customer`.

```postgresql
SELECT 
    customer_sk,
    customer_id,
    customer_name,
    category_name,
    delivery_city_name,
    valid_from,
    valid_to,
    is_current
FROM olap.dim_customer
WHERE customer_id = 893
ORDER BY valid_from ASC;
```

> [View result (scd2_p3)](../results/scd2_p3.html)

The table now holds both versions. The original attributes are retained under `customer_sk = 643`, and the current state is stored under surrogate key `664`.

### Verify point-in-time fact table resolution

Re-querying the past orders demonstrates that past analytics are unchanged. For instance, consider `order_id = 163`.

```postgresql
SELECT 
    fo.order_id,
    fo.order_date_key,
    fo.customer_sk,
    fo.city_sk,
    dc.customer_name,
    dc.category_name,
    ci.city_name,
    dc.is_current
FROM olap.fact_order fo
JOIN olap.dim_customer dc ON fo.customer_sk = dc.customer_sk
JOIN olap.dim_city ci ON fo.city_sk = ci.city_sk
WHERE dc.customer_id = 893 AND fo.order_id = 163;
```

> [View result (scd2_p4)](../results/scd2_p4.html)

Suppose we create an order placed today in `oltp.orders` and `oltp.order_lines`.

```postgresql
INSERT INTO oltp.orders (
    order_id, 
    customer_id, 
    salesperson_person_id, 
    order_date, 
    expected_delivery_date, 
    is_undersupply_backordered
) 
VALUES (
    999999, 
    893, 
    2, 
    CURRENT_DATE, 
    CURRENT_DATE, 
    FALSE
);

INSERT INTO oltp.order_lines (
    order_line_id, 
    order_id, 
    stock_item_id, 
    package_type_id, 
    quantity, 
    unit_price, 
    tax_rate
) 
VALUES (
    999999, 
    999999, 
    1, 
    1, 
    25, 
    120.00, 
    15.000
);
```

Run the query for fact loader in [07_load_facts.sql](../query/07_load_facts.sql), then verify resolution for the new transaction by running the following query in `olap.fact_order`.

```postgresql
SELECT 
    fo.order_id,
    fo.order_date_key,
    fo.customer_sk,
    fo.city_sk,
    dc.customer_name,
    dc.category_name,
    ci.city_name,
    dc.is_current
FROM olap.fact_order fo
JOIN olap.dim_customer dc ON fo.customer_sk = dc.customer_sk
JOIN olap.dim_city ci ON fo.city_sk = ci.city_sk
WHERE fo.order_id = 999999;
```

> [View result (scd2_p5)](../results/scd2_p5.html)

Because the point-in-time join uses a half-open window (`order_date >= valid_from::DATE AND order_date < valid_to::DATE`):

- Today's transaction links to the current version (`customer_sk = 664`) and resolves to Long Beach (`city_sk = 19881`).
- Past transactions remain mapped to `customer_sk = 643` and West Elkton (`city_sk = 36499`).
- Transactions on the boundary day match only the new version, preventing duplicate rows or fanout issues.
