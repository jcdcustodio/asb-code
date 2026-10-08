import re
import time
import polars as pl
from pathlib import Path
from tqdm import tqdm
from db_util import *


CHUNKSIZE = BASE_CHUNKSIZE

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

TABLE_CONFIG = {
    "cities": {
        "latitude": {"type": "coordinate"},
        "longitude": {"type": "coordinate"},
    },
    "customers": {
        "account_opened_date": {"type": "date", "format": "%d/%m/%Y"},
        "delivery_location_lat": {"type": "coordinate"},
        "delivery_location_long": {"type": "coordinate"},
    },
    "orders": {
        "order_date": {"type": "date", "format": "%d/%m/%Y"},                   
        "expected_delivery_date": {"type": "date", "format": "%d/%m/%Y"},       
        "picking_completed_when": {"type": "datetime", "format": "%Y-%m-%d %H:%M:%S%.f"}
    },
    "order_lines": {
        "picking_completed_when": {"type": "datetime", "format": "%Y-%m-%d %H:%M:%S%.f"}
    },
    "invoices": {
        "invoice_date": {"type": "date", "format": "%d/%m/%Y"},                 
        "confirmed_delivery_time": {"type": "datetime", "format": "%Y-%m-%d %H:%M:%S%.f"}
    }
}


def ingest_data(data_path: Path, table_name: str) -> None:
    if not data_path.exists():
        raise FileNotFoundError(f"Missing required source file: {data_path}")

    # Get row count without reading or parsing full contents
    total_rows = (
        pl.scan_csv(data_path, ignore_errors=True)
        .select(pl.len())
        .collect()
        .item()
    )

    # Create iterator that reads raw data in chunks
    data_iter = (
        pl.scan_csv(
            data_path,
            separator=";",
            null_values=["", "NULL", "N/A", "null", "None"],
            ignore_errors=True
        ).collect_batches(chunk_size=CHUNKSIZE)
    )

    total_records = 0
    copy_sql = None

    with get_pg_connection() as conn, conn.cursor() as cur:
        with tqdm(
            total=total_rows,
            desc=f"Ingesting {table_name:<20}",
            unit="rows",
            unit_scale=True,
            dynamic_ncols=True,
            colour="green"
        ) as pbar:

            for batch_index, raw_chunk in enumerate(data_iter):
                # Normalize column names
                chunk = raw_chunk.rename({col: normalize_name(col) for col in raw_chunk.columns})

                # Apply specific datatype casting
                chunk = wrangler(chunk=chunk, table_name=table_name)

                # Prepare column names on the initial batch
                if batch_index == 0:
                    columns_sql = ", ".join(f'"{c}"' for c in chunk.columns)
                    copy_sql = f"COPY oltp.{table_name} ({columns_sql}) FROM STDIN"

                # Stream binary tuples to Postgres via COPY
                with cur.copy(copy_sql) as copy:
                    for row in chunk.iter_rows():
                        copy.write_row(row)

                batch_records = len(chunk)
                total_records += batch_records

                pbar.update(batch_records)

            # Record ingestion metadata
            cur.execute(
                """
                INSERT INTO oltp._ingestion_metadata 
                (source_file, records_loaded, status) 
                VALUES (%s, %s, %s);
                """,
                (data_path.name, total_records, "SUCCESS")
            )

        conn.commit()


def wrangler(chunk: pl.DataFrame, table_name: str) -> pl.DataFrame:
    settings = TABLE_CONFIG.get(table_name)
    if not settings:
        return chunk

    edited_cols = []
    for col_name, col_setting in settings.items():
        if col_name not in chunk.columns:
            continue

        # Strip padding to prepare with parsing
        stripped_col = pl.col(col_name).cast(pl.Utf8).str.strip_chars()

        # Get mapped datatype
        target_type = col_setting["type"]

        # Handles latitude and longitude
        if target_type == "coordinate":
            edited_cols.append(
                stripped_col
                .str.replace(",", ".")
                .cast(pl.Float64, strict=False)
                .alias(col_name)
            )

        # Handles dates (MM/DD/YYYY)
        if target_type == "date":
            fmt = col_setting.get("format", "%Y-%m-%d")
            edited_cols.append(
                stripped_col
                .str.to_date(format=fmt, strict=False)
                .alias(col_name)
            )

        # Handles timestamps (YYYY-MM-DD HH:MM:SS.0000000)
        if target_type == "datetime":
            fmt = col_setting.get("format", "%Y-%m-%d %H:%M:%S")
            edited_cols.append(
                stripped_col
                .str.to_datetime(format=fmt, strict=False)
                .alias(col_name)
            )

    return chunk.with_columns(edited_cols)


def normalize_name(name: str) -> str:
    s = name.strip()

    # Insert underscore between lowercase/digit and uppercase
    s = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s)

    # Insert underscore between acronyms and trailing capitalized words
    s = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", s)

    return s.lower()


def run_oltp_ingestion(data_dir: Path) -> None:
    start_time = time.time()

    # Discover all raw data files present in the directory
    data_files = {p.name for p in data_dir.glob("*.csv")}

    # Filter based on tables present in the database
    input_tables = [
        (filename, table_name)
        for filename, table_name in INGESTION_TABLES
        if filename in data_files
    ]
    if not input_tables:
        print(f"No matching files found in {data_dir}.")
        return

    for data_file, table_name in input_tables:
        ingest_data(data_dir / data_file, table_name)

    elapsed = time.time() - start_time
    print("All tables ingested successfully.")
    print(f"-> Elapsed time: {elapsed:.2f}s")


if __name__ == "__main__":
    DATA_DIR = Path("data/raw").resolve()

    run_oltp_ingestion(data_dir=DATA_DIR)
