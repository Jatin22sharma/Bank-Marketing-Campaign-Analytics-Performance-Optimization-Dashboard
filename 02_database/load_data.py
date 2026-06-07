# scripts/etl_load.py
import pandas as pd
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus          # ← add this

# --- Config ---
DB_USER     = "root"
DB_PASSWORD = quote_plus("jatin@22")        # ← wraps @ as %40 safely
DB_HOST     = "localhost"
DB_NAME     = "bank_campaign"

# --- Load CSV ---
df = pd.read_csv("01_data/bank_marketing.csv", sep=";")
print(f"Loaded {len(df)} rows, {df.shape[1]} columns")
print(df.dtypes)

# --- Basic cleaning ---
df.columns = df.columns.str.strip().str.lower().str.replace("-", "_")
df["y_binary"] = (df["y"] == "yes").astype(int)
df["pdays"]    = df["pdays"].replace(-1, None)

# --- Create engine & load ---
engine = create_engine(f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}")

with engine.connect() as conn:
    conn.execute(text("CREATE DATABASE IF NOT EXISTS bank_campaign"))

df.to_sql("campaigns", engine, if_exists="replace", index=False, chunksize=1000)
print("Data loaded to MySQL successfully.")
print(df.head())