# OLAP Schema

The OLAP schema forms a constellation schema (two fact tables sharing a conformed dimensional core):

1. **Conformed Dimensions:** Five shared dimension tables integrate with both business processes. `dim_date` handles calendar and fiscal reporting periods; `dim_city` denormalizes cities, provinces, and countries; `dim_stock_item` flattens item specifications, packaging, and colors; and `dim_employee` captures staff representatives.
2. **Slowly Changing Dimension (SCD Type 2):** `dim_customer` tracks historical changes over time using validity windows (`valid_from`, `valid_to`) and an `is_current` active flag. Fact pipeline joins resolve against the customer record valid at transaction time using half-open date intervals.
3. **Fact Orders:** Grain is one row per order line (`order_line_sk`). It tracks fulfillment metrics, order quantities, price totals with and without tax, and backorder flags.
4. **Fact Sales:** Grain is one row per invoice line (`sale_line_sk`). In addition to sales quantities, invoice prices, and tax metrics, it stores line-level profitability (`line_profit`), process lag (`days_order_to_invoice`), and a degenerate order reference (`order_id`) linking back to the originating order.

```mermaid
erDiagram
    DIM_DATE ||--o{ FACT_ORDER : "placed on"
    DIM_CUSTOMER ||--o{ FACT_ORDER : "ordered by"
    DIM_CITY ||--o{ FACT_ORDER : "delivered to"
    DIM_STOCK_ITEM ||--o{ FACT_ORDER : "contains"
    DIM_EMPLOYEE ||--o{ FACT_ORDER : "managed by"

    DIM_DATE ||--o{ FACT_SALE : "invoiced on"
    DIM_CUSTOMER ||--o{ FACT_SALE : "billed to"
    DIM_CITY ||--o{ FACT_SALE : "delivered to"
    DIM_STOCK_ITEM ||--o{ FACT_SALE : "sold"
    DIM_EMPLOYEE ||--o{ FACT_SALE : "sold by"

    DIM_DATE {
        int date_key PK
        date full_date
        int day_of_month
        int day_of_week
        text day_name
        int calendar_month
        text calendar_month_name
        int calendar_quarter
        int calendar_year
        int fiscal_month
        int fiscal_quarter
        int fiscal_year
        boolean is_weekend
    }

    DIM_CITY {
        int city_sk PK
        int city_id
        text city_name
        text state_province_code
        text state_province_name
        text country_name
        text sales_territory
    }

    DIM_CUSTOMER {
        int customer_sk PK
        int customer_id
        text customer_name
        text category_name
        text buying_group_name
        text delivery_city_name
        timestamp valid_from
        timestamp valid_to
        boolean is_current
    }

    DIM_STOCK_ITEM {
        int stock_item_sk PK
        int stock_item_id
        text stock_item_name
        text brand
        text color_name
        text package_type_name
        numeric unit_price
        numeric tax_rate
    }

    DIM_EMPLOYEE {
        int employee_sk PK
        int employee_id
        text full_name
        boolean is_salesperson
    }

    FACT_ORDER {
        int order_line_sk PK
        int order_id
        int order_line_id
        int order_date_key FK
        int customer_sk FK
        int city_sk FK
        int stock_item_sk FK
        int salesperson_sk FK
        boolean is_undersupply_backordered
        int ordered_quantity
        numeric unit_price
        numeric tax_rate
        numeric tax_amount
        numeric extended_price_excl_tax
        numeric extended_price_incl_tax
    }

    FACT_SALE {
        int sale_line_sk PK
        int invoice_id
        int invoice_line_id
        int order_id
        int invoice_date_key FK
        int customer_sk FK
        int city_sk FK
        int stock_item_sk FK
        int salesperson_sk FK
        int invoiced_quantity
        numeric unit_price
        numeric tax_rate
        numeric tax_amount
        numeric extended_price_excl_tax
        numeric extended_price_incl_tax
        numeric line_profit
        int days_order_to_invoice
    }

```
