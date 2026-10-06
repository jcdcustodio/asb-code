import psycopg
from decouple import config
from sqlalchemy import create_engine


DB_HOST = config("POSTGRES_HOST", default="localhost", cast=str)
DB_PORT = config("POSTGRES_PORT", default="5432", cast=str)
DB_USERNAME = config("POSTGRES_USER", default="user", cast=str)
DB_PASSWORD = config("POSTGRES_PASSWORD", default="user", cast=str)
DB_NAME = config("POSTGRES_DB", default="postgres", cast=str)
DB_URL = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"


def get_engine():
    return create_engine(DB_URL)

def get_raw_connection():
    return psycopg.connect(DB_URL)
