# OLTP Schema

The OLTP schema is organized into four functional domains:

1. **Geographic Hierarchy:** `countries` forms the root of geographic validation. Each country cascades down to `state_provinces`, which in turn associates with `cities`. These cities link directly to `customers.delivery_city_id` for order logistics.
2. **Customer & Organization Entities:** `customers` maps to classification entities `customer_categories` and `buying_groups` via direct foreign keys. It also contains logical identifier references to `people` (`primary_contact_person_id`, `alternate_contact_person_id`) and self-references (`bill_to_customer_id`).
3. **Product Catalog:** `stock_items` joins `colors` (for variant color tagging) and `package_types` via `unit_package_id`.
4. **Transactional Pipeline:** `orders` and `invoices` share dual integration patterns. Both tie back to `customers` and `people` (`salesperson_person_id`). Child tables `order_lines` and `invoice_lines` capture transaction line items linked back to `stock_items` and `package_types`. `_ingestion_metadata` is an independent utility table tracking pipeline execution.

```mermaid
erDiagram
    COUNTRIES ||--o{ STATE_PROVINCES : "contains"
    STATE_PROVINCES ||--o{ CITIES : "contains"
    CITIES ||--o{ CUSTOMERS : "delivery destination for"

    CUSTOMER_CATEGORIES ||--o{ CUSTOMERS : "classifies"
    BUYING_GROUPS ||--o{ CUSTOMERS : "groups"

    CUSTOMERS ||--o{ ORDERS : "places"
    PEOPLE ||--o{ ORDERS : "sales representative on"
    ORDERS ||--|{ ORDER_LINES : "contains"

    CUSTOMERS ||--o{ INVOICES : "billed to"
    ORDERS ||--o{ INVOICES : "invoiced by"
    PEOPLE ||--o{ INVOICES : "sales representative on"
    INVOICES ||--|{ INVOICE_LINES : "contains"

    COLORS ||--o{ STOCK_ITEMS : "colors"
    PACKAGE_TYPES ||--o{ STOCK_ITEMS : "unit package for"
    STOCK_ITEMS ||--o{ ORDER_LINES : "ordered in"
    STOCK_ITEMS ||--o{ INVOICE_LINES : "billed in"
    PACKAGE_TYPES ||--o{ ORDER_LINES : "packaged as"
    PACKAGE_TYPES ||--o{ INVOICE_LINES : "packaged as"

    COUNTRIES {
        int country_id PK
        text country_name
        text formal_name
        int latest_recorded_population
        text continent
        text region
        text subregion
    }

    STATE_PROVINCES {
        int state_province_id PK
        text state_province_code
        text state_province_name
        int country_id FK
        text sales_territory
        int latest_recorded_population
    }

    CITIES {
        int city_id PK
        text city_name
        int state_province_id FK
        numeric latitude
        numeric longitude
        int latest_recorded_population
    }

    CUSTOMER_CATEGORIES {
        int customer_category_id PK
        text customer_category_name
    }

    BUYING_GROUPS {
        int buying_group_id PK
        text buying_group_name
    }

    CUSTOMERS {
        int customer_id PK
        text customer_name
        int bill_to_customer_id
        int customer_category_id FK
        int buying_group_id FK
        int primary_contact_person_id
        int alternate_contact_person_id
        int delivery_method_id
        int delivery_city_id FK
        numeric credit_limit
        date account_opened_date
        numeric standard_discount_percentage
        boolean is_statement_sent
        boolean is_on_credit_hold
        int payment_days
        text phone_number
        text website_url
        text delivery_address_line
        numeric delivery_location_lat
        numeric delivery_location_long
    }

    PEOPLE {
        int person_id PK
        text full_name
        text preferred_name
        text search_name
        boolean is_employee
        boolean is_salesperson
    }

    COLORS {
        int color_id PK
        text color_name
    }

    PACKAGE_TYPES {
        int package_type_id PK
        text package_type_name
    }

    STOCK_ITEMS {
        int stock_item_id PK
        text stock_item_name
        int supplier_id
        int color_id FK
        int unit_package_id FK
        int outer_package_id
        text brand
        text size
        int lead_time_days
        int quantity_per_outer
        boolean is_chiller_stock
        text barcode
        numeric tax_rate
        numeric unit_price
        numeric recommended_retail_price
        numeric typical_weight_per_unit
    }

    ORDERS {
        int order_id PK
        int customer_id FK
        int salesperson_person_id FK
        int picked_by_person_id
        int contact_person_id
        int backorder_order_id
        date order_date
        date expected_delivery_date
        int customer_purchase_order_number
        boolean is_undersupply_backordered
        timestamp picking_completed_when
    }

    ORDER_LINES {
        int order_line_id PK
        int order_id FK
        int stock_item_id FK
        text description
        int package_type_id FK
        int quantity
        numeric unit_price
        numeric tax_rate
        int picked_quantity
        timestamp picking_completed_when
    }

    INVOICES {
        int invoice_id PK
        int customer_id FK
        int bill_to_customer_id
        int order_id FK
        int delivery_method_id
        int contact_person_id
        int accounts_person_id
        int salesperson_person_id FK
        int packed_by_person_id
        date invoice_date
        int customer_purchase_order_number
        text delivery_instructions
        int total_dry_items
        int total_chiller_items
        timestamp confirmed_delivery_time
        text confirmed_received_by
    }

    INVOICE_LINES {
        int invoice_line_id PK
        int invoice_id FK
        int stock_item_id FK
        text description
        int package_type_id FK
        int quantity
        numeric unit_price
        numeric tax_rate
        numeric tax_amount
        numeric line_profit
        numeric extended_price
    }

    INGESTION_METADATA {
        int ingest_id PK
        text source_file
        int records_loaded
        timestamp loaded_at
        text status
    }

```