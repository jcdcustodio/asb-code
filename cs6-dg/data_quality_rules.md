# Data Quality Rules

The rules matrix defines enforceable requirements across all tables. By default, records that fail atleast one rule get place under **quarantine**.

| Rule ID | DQ Dimension | Entity / Field | Rule Definition | Business Rationale | Failure Handling |
| --- | --- | --- | --- | --- | --- |
| **ORD\_UNIQ\_01** | Uniqueness | `orders.order_id` | `COUNT(order_id) = 1` | Eliminates duplicated orders that artificially inflate order counts. | Quarantine |
| **ORD\_COMP\_01** | Completeness | `orders.customer_id` | `customer_id IS NOT NULL` | Prevents orphaned orders detached from customer entities. | Quarantine |
| **ORD\_VAL\_01** | Validity | `orders.order_status` | `order_status IN ('delivered', 'shipped', 'canceled', 'invoiced', 'processing', 'created', 'approved', 'unavailable')` | Rejects unapproved lifecycle statuses that distort funnel tracking. | Quarantine |
| **ORD\_CONS\_01** | Consistency | `orders.timestamps` | `delivered_customer_date >= purchase_timestamp` | Deliveries recorded before purchase represent sequence errors. | Quarantine |
| **ORD\_CONS\_02** | Consistency | `orders.timestamps` | `approved_at >= purchase_timestamp` | Approvals cannot precede order checkout. | Quarantine |
| **ITM\_UNIQ\_01** | Uniqueness | `order_items.(order_id, order_item_id)` | Compound key must be distinct | Line items must uniquely identify every item sold in an order. | Quarantine |
| **ITM\_REAS\_01** | Reasonability | `order_items.price` | `price > 0.00` | Financial calculations require positive unit values. | Quarantine |
| **ITM\_REAS\_02** | Reasonability | `order_items.freight_value` | `freight_value >= 0.00` | Freight charges cannot be negative numbers. | Quarantine |
| **PAY\_VAL\_01** | Validity | `order_payments.payment_type` | `payment_type IN ('credit_card', 'boleto', 'voucher', 'debit_card')` | Restricts records to accepted payment gateways. | Quarantine |
| **PAY\_REAS\_01** | Reasonability | `order_payments.payment_value` | `payment_value > 0.00` | Zero-value transaction records indicate failed processing. | Quarantine |
| **REV\_UNIQ\_01** | Uniqueness | `order_reviews.review_id` | `COUNT(review_id) = 1` | Prevents duplicate survey records from skewing customer satisfaction metrics and review counts. | Quarantine |
| **REV\_VAL\_01** | Validity | `order_reviews.review_score` | `review_score BETWEEN 1 AND 5` | Review scoring requires compliance with the standardized 1–5 scale. | Quarantine |
| **REV\_VAL\_02** | Validity | `order_reviews.review_creation_date` | If present, `review_creation_date` must parse as a valid timestamp | Prevents downstream Gold layer casting errors and ensures accurate review turnaround time tracking. | Quarantine |
| **REV\_VAL\_03** | Validity | `order_reviews.review_answer_timestamp` | If present, `review_answer_timestamp` must parse as a valid timestamp | Prevents downstream Gold layer casting errors and ensures reliable SLA response calculations. | Quarantine |
| **REV\_CONS\_01** | Consistency | `order_reviews.timestamps` | `review_answer_timestamp >= review_creation_timestamp` | Answers cannot logically precede review ticket creation; invalid sequences corrupt response time metrics. | Quarantine |
| **PROD\_REAS\_01** | Reasonability | `products.dimensions` | `weight_g > 0 AND length_cm > 0 AND height_cm > 0 AND width_cm > 0` | Physical goods must have positive dimensional measurements. | Quarantine |
| **CUST\_COMP\_01** | Completeness | `customers.customer_unique_id` | `customer_unique_id IS NOT NULL` | Unique identity is required for customer lifetime frequency metrics. | Quarantine |
| **SELL\_COMP\_01** | Completeness | `sellers.zip_code_prefix` | `seller_zip_code_prefix IS NOT NULL` | Sellers must have a valid zip code to link regional fulfillment logistics. | Quarantine |
| **GEO\_VAL\_01** | Validity | `geolocation.coordinates` | `latitude BETWEEN -34.0 AND 5.5 AND longitude BETWEEN -74.0 AND -34.0` | Coordinates must fall within Brazilian land borders. | Quarantine |
