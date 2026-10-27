# Analytical/Semantic Model

The analytical model utilizes a constellation/multi-fact star schema. Instead of flattening the entire e-commerce dataset into a single massive table—which causes catastrophic data duplication and metric inflation—the model separates data into shared contextual dimensions and isolated event-driven fact tables based on their precise business granularities.

## ER Diagram

```mermaid
erDiagram
    dim_date ||--o{ fact_orders : "1:N (purchase_date_key)"
    dim_customers ||--o{ fact_orders : "1:N (customer_id)"
    dim_products ||--o{ fact_order_items : "1:N (product_id)"
    dim_sellers ||--o{ fact_order_items : "1:N (seller_id)"
    fact_orders ||--o{ fact_order_items : "1:N (order_id)"
    fact_orders ||--o{ fact_order_payments : "1:N (order_id)"
    fact_orders ||--o{ fact_order_reviews : "1:N (order_id)"

    dim_date {
        date date_key PK
        int year
        int quarter
        string year_quarter
        int month
        string year_month
        string month_name
        int day_of_week
        string day_name
        int is_weekend
    }

    dim_customers {
        string customer_id PK
        string customer_unique_id
        string zip_code_prefix
        string city
        string state
        float latitude
        float longitude
        int lifetime_orders_count
        string customer_type
    }

    dim_products {
        string product_id PK
        string product_category
        int product_name_length
        int product_description_length
        int product_photos_quantity
        float product_weight_grams
        float product_length_cm
        float product_height_cm
        float product_width_cm
    }

    dim_sellers {
        string seller_id PK
        string zip_code_prefix
        string city
        string state
        float latitude
        float longitude
    }

    fact_orders {
        string order_id PK
        string customer_id FK
        string order_status
        timestamp purchase_timestamp
        date purchase_date_key FK
        timestamp approved_timestamp
        timestamp carrier_delivered_timestamp
        timestamp customer_delivered_timestamp
        timestamp estimated_delivery_timestamp
        int is_delivered
        float delivery_duration_days
        float estimated_delivery_duration_days
        int is_late_delivery
    }

    fact_order_items {
        string order_id PK, FK
        int order_item_id PK
        string product_id FK
        string seller_id FK
        timestamp shipping_limit_timestamp
        decimal price
        decimal freight_value
        decimal gross_item_revenue
    }

    fact_order_payments {
        string order_id PK, FK
        int payment_sequential PK
        string payment_type
        int payment_installments
        decimal payment_value
    }

    fact_order_reviews {
        string review_id PK
        string order_id FK
        int review_score
        timestamp review_creation_timestamp
        timestamp review_answer_timestamp
    }
```

## Dimensional Layer - Context

The dimensions serve as the "Who, What, Where, and When" of the marketplace. These are the lookup tables containing unique, non-duplicated entities used for filtering and slicing the dashboard visuals.

- `dim_customers`: Granularity is one row per unique customer location. It deduplicates the raw geolocation dataset to link `customer_id` directly to their `city`, `state`, and `zip_code_prefix`.
- `dim_sellers`: Granularity is one row per unique seller. Similar to the customer dimension, it ties `seller_id` to operational geographies to enable logistical mapping and regional delivery tracking.
- `dim_products`: Granularity is one row per unique item. It maps `product_id` to physical specifications (`weight_g`, `photos_qty`) and utilizes a joined mapping table to natively translate Portuguese categories into English.
- `dim_date`: A standard calendar dimension linked to the various lifecycle timestamps (purchase date, approved date, delivered date) to enable time-intelligence DAX functions and cohort analysis.

## Fact Layer - Metrics and Events

The fact tables store the quantitative business events. By isolating these into four distinct tables, the model guarantees that metrics (like freight value or review scores) are accurately calculated even when a single order behaves unexpectedly.

- `fact_orders` (Header Grain): One row equals one checkout event. It stores the exact timestamps of the fulfillment lifecycle (estimated vs. actual delivery date) and the overarching `order_status` (including canceled or unavailable orders that lack line items).
- `fact_order_items` (Line-Item Grain): One row equals one physical product sold. This is the core financial table containing `price`, `freight_value`, and foreign keys bridging to both `dim_sellers` and `dim_products`.
- `fact_payments` (Transaction Grain): One row equals one payment method used. If a customer splits an order between a credit card and a voucher, it generates two distinct rows here, both tied back to the parent `order_id`.
- `fact_order_reviews` (Feedback Grain): One row equals one customer survey response, storing the exact 1-to-5 `review_score`.

## Resolving Grain and Filtering Flow

Because the schema is a constellation rather than a simple star, the `fact_orders` table acts as a central bridge mechanism.

The primary technical challenge in this architecture is the single-direction flow of filters. In a standard BI model, relationships flow strictly 1-to-Many. If a user clicks a specific `product_category` in `dim_products`, the filter successfully flows down into `fact_order_items`. However, it natively stops there. To calculate the average review score for that specific product category, the filter must traverse "upstream" from `fact_order_items` into `fact_orders`, and then back down into `fact_order_reviews`.

This was resolved dynamically using the `CROSSFILTER(..., BOTH)` DAX pattern. Instead of turning on hardcoded bi-directional cross-filtering (which creates ambiguous paths and severely degrades dashboard processing speed), the measure activates the reverse filter path only for the microsecond that specific calculation computes, preserving the overall integrity of the model.
