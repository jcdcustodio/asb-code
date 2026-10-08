from db_util import get_pg_connection


ASSERTIONS = [
    # SCD Type 2 Integrity: No business key can have more than one active record
    (
        """
        SELECT customer_id, COUNT(*) 
        FROM olap.dim_customer 
        WHERE is_current = TRUE 
        GROUP BY customer_id 
        HAVING COUNT(*) > 1;
        """,
        "SCD2 Violation: Found multiple active dimension records for a single customer natural key!"
    ),
    # Fact Integrity: Quantity must never be negative or null in sales
    (
        """
        SELECT COUNT(*) 
        FROM olap.fact_sale 
        WHERE invoiced_quantity <= 0 OR invoiced_quantity IS NULL;
        """,
        "Fact Quality Violation: Detected invalid or null invoiced quantities in fact_sale!"
    ),
    # Referencing Integrity: Every fact row must resolve to a valid surrogate key
    (
        """
        SELECT COUNT(*) 
        FROM olap.fact_sale 
        WHERE customer_sk = 0 OR customer_sk IS NULL;
        """,
        "Dimensional Orphan Warning: Sales facts present with unresolved customer surrogate keys."
    ),
    # Temporal Sequence Integrity: Invoices cannot precede their parent orders
    (
        """
        SELECT COUNT(*) 
        FROM olap.fact_sale 
        WHERE days_order_to_invoice < 0;
        """,
        "Chronology Error: Order date is logged after invoice date!"
    )
]


def run_data_quality_suite():
    print("--- Running Data Quality Assurance Checks ---")
    with get_pg_connection() as conn, conn.cursor() as cur:
        for query, error_msg in ASSERTIONS:
            cur.execute(query)
            results = cur.fetchall()
            if results and (results[0][0] > 0 if len(results[0]) == 1 else len(results) > 0):
                raise AssertionError(f"CHECK FAILED\n{error_msg}\n-> Details: {results}")
    print("CHECK PASSED")
    print("All Data Quality Assertions passed successfully.")


if __name__ == "__main__":
    run_data_quality_suite()
