import polars as pl
from pathlib import Path
from db_util import get_engine, get_raw_connection


# Priority-ordered dependencies: Parents must load before children
INGESTION_TABLES = [
    ("Application.Countries.csv", "countries"),
    ("Application.StateProvinces.csv", "state_provinces"),
    ("Application.Cities.csv", "cities"),
    ("Sales.CustomerCategories.csv", "customer_categories"),
    ("Sales.BuyingGroups.csv", "buying_groups"),
    ("Application.People.csv", "people"),
    ("Warehouse.Colors.csv", "colors"),
    ("Warehouse.PackageTypes.csv", "package_types"),
    ("Warehouse.StockItems.csv", "stock_items"),
    ("Sales.Customers.csv", "customers"),
    ("Sales.Orders.csv", "orders"),
    ("Sales.OrderLines.csv", "order_lines"),
    ("Sales.Invoices.csv", "invoices"),
    ("Sales.InvoiceLines.csv", "invoice_lines"),
]


def clean_and_ingest_file(csv_path: Path, table_name: str):
    if not csv_path.exists():
        raise FileNotFoundError(f"Missing required source file: {csv_path}")

    # Read CSV; infer null values on common edge-case strings
    df = pl.read_csv(
        csv_path,
        null_values=["", "NULL", "N/A", "null", "None"],
        ignore_errors=True
    )
    
    # Strip spaces from column headers
    df = df.rename({col: col.strip() for col in df.columns})

    engine = get_engine()
    
    # Bulk insertion into database
    # Using 'append' to respect table definitions from 01_init_oltp.sql
    df.to_pandas().to_sql(
        name=table_name,
        schema="oltp",
        con=engine,
        if_exists="append",
        index=False,
        chunksize=10_000,
        method="multi"
    )

    # Record operational metadata
    with get_raw_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO oltp._ingestion_metadata 
                (source_file, records_loaded, status) 
                VALUES (%s, %s, %s);
                """,
                (csv_path.name, len(df), "SUCCESS")
            )
        conn.commit()

    print(f"Successfully ingested {len(df):>7} records into oltp.{table_name}")


def run_oltp_ingestion(data_dir: Path):
    for csv_file, table_name in INGESTION_TABLES:
        clean_and_ingest_file(data_dir / csv_file, table_name)


if __name__ == "__main__":
    DATA_DIR = Path("data/raw").resolve()

    run_oltp_ingestion(data_dir=DATA_DIR)