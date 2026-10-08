import argparse
import time
from pathlib import Path
from ingest_oltp import run_oltp_ingestion
from check_quality import run_data_quality_suite
from db_util import *


def execute_query(filepath: Path):
    print(f"Executing query from {filepath.name}")
    with get_pg_connection() as conn:
        start_time = time.time()

        with conn.cursor() as cur:
            cur.execute(filepath.read_text(encoding="utf-8"))
        conn.commit()

        elapsed = time.time() - start_time
        print(f"-> Completed in {elapsed:.2f}s")


def run_pipeline(data_directory: Path):
    print("===========================")
    print("     STARTING PIPELINE     ")
    print("===========================")

    # 1. Source Availability Checks
    if not data_directory.exists():
        raise FileNotFoundError(f"Input directory does not exist: \n{data_directory}")

    # 2. Database Preparation
    execute_query(Path("sql/oltp/01_init_oltp.sql").resolve())
    execute_query(Path("sql/olap/02_init_olap.sql").resolve())

    # 3. Ingestion into OLTP
    run_oltp_ingestion(data_directory)

    # 4. Seed Deterministic Dimensions
    execute_query(Path("sql/olap/03_load_dim_date.sql").resolve())

    # 5. Seed Unknowns
    execute_query(Path("sql/olap/04_insert_unknowns.sql").resolve())

    # 5. Transform and Load Dimensions (including SCD2 for Customers)
    execute_query(Path("sql/olap/05_load_dim_scd1.sql").resolve())
    execute_query(Path("sql/olap/06_customer_scd2.sql").resolve())

    # 6. Transform and Load Facts
    execute_query(Path("sql/olap/07_load_facts.sql").resolve())

    # 7. Run Data Quality Checks
    run_data_quality_suite()

    print("===================================================")
    print("     PIPELINE EXECUTION COMPLETED SUCCESSFULLY     ")
    print("===================================================")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run WWI Data Pipeline")
    parser.add_argument(
        "--data-dir", 
        type=str, 
        default="data/raw", 
        help="Path to directory containing input CSVs"
    )
    args = parser.parse_args()
    run_pipeline(Path(args.data_dir))
