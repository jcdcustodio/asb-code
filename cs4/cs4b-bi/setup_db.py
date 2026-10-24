import re
from pathlib import Path

import duckdb
import kagglehub
from decouple import config
from tqdm import tqdm


DB_HOST = config("POSTGRES_HOST", default="localhost", cast=str)
DB_PORT = config("POSTGRES_PORT", default=5432, cast=int)
DB_NAME = config("POSTGRES_DB", default="asb_oltp", cast=str)
DB_USERNAME = config("POSTGRES_USER", default="user", cast=str)
DB_PASSWORD = config("POSTGRES_PASSWORD", default="user", cast=str)
DUCKDB_OLTP_CONNECTION = config("DUCKDB_OLTP_CONNECTION", default="data/duckdb/asb_oltp.duckdb", cast=str)

KAGGLE_DATASETS = [
    "olistbr/brazilian-ecommerce"
]
TARGET_SCHEMA = "kaggle"


def clean_file_name(file_name: str) -> str:
    # Get only the file name without extension
    cleaned = file_name.lower().split(".")[0]
    # Replace all whitespaces and special characters with underscores
    cleaned = re.sub(r"[^\w]+", "_", cleaned)
    # Strip leading and trailing underscores and collapse consecutive underscores 
    return re.sub(r"_+", "_", cleaned).strip("_")


def get_duckdb_conn(db_path: str) -> duckdb.DuckDBPyConnection:
    """Return DuckDB generic connection."""
    
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    return duckdb.connect(db_path)


def run_sql(
    conn: duckdb.DuckDBPyConnection, 
    sql: str, 
    run_alias: int = 0,
    text_to_replace: str | None = None, 
    text_replacement: str | None = None
    ) -> None: 
    """Run SQL scripts in DuckDB."""

    conn.sql(sql)

    # Run the same script on attached database via alias
    if all(t is not None for t in (text_to_replace, text_replacement)) and run_alias == 1:
        sql_new = sql.replace(text_to_replace, f"{text_replacement}")
        conn.sql(sql_new)


def create_schema(
        conn: duckdb.DuckDBPyConnection, 
        schema_name: str,
        run_alias: int = 0,
        pg_alias: str = "pg_oltp"
    ) -> None:
    """Create schema_name on DuckDB connection."""

    run_sql(conn, f"CREATE SCHEMA IF NOT EXISTS {schema_name};")

    if run_alias == 1:
        run_sql(conn, f"CREATE SCHEMA IF NOT EXISTS {pg_alias}.{schema_name};")


def attach_postgres(
        conn: duckdb.DuckDBPyConnection,
        pg_host: str,
        pg_port: str,
        pg_db_name: str,
        pg_username: str,
        pg_password: str,
        pg_alias: str = "pg_oltp"
    ) -> tuple[int, str | None]:
    """
    Attach PostgreSQL to DuckDB. Returns (success_status, pg_alias)

    success_status = 1 means successful, 0 means failed
    
    """

    try:
        # Install and load postgres library
        print("Installing and loading postgres library...", flush=True)
        conn.sql("INSTALL postgres;")
        print("Done installing and loading postgres library.", flush=True)
        conn.sql("LOAD postgres;")

        # Construct SQL ATTACH statement 
        attach_stmt = (
            f"ATTACH 'host={pg_host} port={pg_port} dbname={pg_db_name} "
            f"user={pg_username} password={pg_password}' AS {pg_alias} (TYPE POSTGRES);"
        )

        # Attach postgres
        print(attach_stmt)
        conn.sql(attach_stmt)
        print("Done attaching PostgreSQL database.", flush=True)

        # Handling nulls
        conn.sql("SET pg_null_byte_replacement = '?';")

        return (1, pg_alias)
    
    except Exception as e:
        print(f"PostgreSQL attachment failed: {e}.")
        print("Skipping Postgres table creation. Writing to DuckDB only.")
        return (0, None)


def get_kaggle_data_path(kaggle_dataset: str, file_type: str = "csv"):
    """
    Returns a list of paths containing the download Kaggle datasets.

    """

    data_path = kagglehub.dataset_download(
        kaggle_dataset,
        output_dir=Path("./data/raw").resolve(),
    )
    files = list(Path(data_path).glob(f"*.{file_type}"))
 
    return files


if __name__ == "__main__":
    # Get generic DuckDB connection to be used for all databases processes
    conn_duckdb = get_duckdb_conn(DUCKDB_OLTP_CONNECTION)
    print(f"Connected to DuckDB database: {DUCKDB_OLTP_CONNECTION}")

    # Attach PostgreSQL database to DuckDB
    pg_attach_success, pg_alias = attach_postgres(
        conn=conn_duckdb,
        pg_host=DB_HOST,
        pg_port=DB_PORT,
        pg_db_name=DB_NAME,
        pg_username=DB_USERNAME,
        pg_password=DB_PASSWORD,
        pg_alias="pg_oltp"
    )

    # Ensure schema exists in DuckDB and PostgreSQL
    create_schema(
        conn=conn_duckdb, 
        schema_name=TARGET_SCHEMA, 
        run_alias=pg_attach_success,
        pg_alias=pg_alias
    )

    # Read all downloaded data files from Kaggle; Note that this only accommodates CSV files
    print("Create tables for Kaggle datasets...")
    for kaggle_dataset in tqdm(KAGGLE_DATASETS, leave=False):
        print(f"Downloading {kaggle_dataset} via kagglehub...")
        dataset_files = get_kaggle_data_path(kaggle_dataset)

        print(f"Loading {len(dataset_files)} tables into DuckDB and PostgreSQL...")
        for f in tqdm(dataset_files, leave=False):
            table_name = clean_file_name(f.name)
            posix_path = f.as_posix()

            # Query template
            sql = f"""
                CREATE OR REPLACE TABLE {TARGET_SCHEMA}.{table_name} AS 
                SELECT * FROM read_csv('{posix_path}');
            """

            # Ingest into local DuckDB database and attached PostgreSQL container
            run_sql(
                conn=conn_duckdb, 
                sql=sql, 
                run_alias=pg_attach_success,
                text_to_replace=f"CREATE OR REPLACE TABLE {TARGET_SCHEMA}.",
                text_replacement=f"CREATE OR REPLACE TABLE {pg_alias}.{TARGET_SCHEMA}."
            )

    print("Setup complete. Data available in:")
    print(f" - DuckDB: {DUCKDB_OLTP_CONNECTION}")
    print(f" - PostgreSQL: {DB_NAME}.{TARGET_SCHEMA}.*")