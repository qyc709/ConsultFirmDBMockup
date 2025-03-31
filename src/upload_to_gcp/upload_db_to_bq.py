from .gcp_setup import *
from google.cloud.exceptions import NotFound
import os
from google.cloud import bigquery
from sqlalchemy import create_engine, inspect
from google.api_core import exceptions
import pandas as pd

def upload_sqlite_to_bigquery(version: str, db_dir: str): 

    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = key_path
    db_path = f"{db_dir}/consultingFirm_{version}.db"
    engine = create_engine(f"sqlite:///{db_path}")
    inspector = inspect(engine)
    bq_client = bigquery.Client(project=project_id)

    dataset_id = f"{project_id}.{database_name}_{version}"
    dataset = bigquery.Dataset(dataset_id)

    try:
        # Check if dataset exists, if not create it
        bq_client.get_dataset(dataset_id)
    except exceptions.NotFound:
        # Dataset does not exist, create it
        dataset = bq_client.create_dataset(dataset)
        print(f"Created dataset {dataset_id}")

    sqlite_to_bq_type = {
        "INTEGER": "INTEGER",
        "VARCHAR": "STRING",
        "TEXT": "STRING",
        "REAL": "FLOAT",
        "FLOAT": "FLOAT",
        "NUMERIC": "NUMERIC",
        "DATE": "DATE",
        "DATETIME": "DATETIME",
        "BOOLEAN": "BOOLEAN",
    }

    tables = [
        "Title", "ProjectTeam", "Payroll", "ConsultantTitleHistory", "ProjectBillingRate",
        "BusinessUnit", "Consultant", "ConsultantDeliverable", "Project",
        "Deliverable", "Client", "ProjectExpense", "Location"
    ]

    for table in tables:
        df = pd.read_sql(f"SELECT * FROM {table}", engine)
        columns = inspector.get_columns(table)

        schema = []
        for col in columns:
            col_name = col['name']
            raw_type = str(col['type']).upper()
            base_type = raw_type.split("(")[0]
            bq_type = sqlite_to_bq_type.get(base_type, "STRING")

            if col_name in df.columns:
                sample_series = df[col_name].dropna()
                if bq_type == "INTEGER":
                    if sample_series.apply(lambda x: isinstance(x, float) and not x.is_integer()).any():
                        bq_type = "FLOAT"
                    elif sample_series.apply(lambda x: isinstance(x, str)).any():
                        bq_type = "STRING"
                elif bq_type == "FLOAT":
                    if sample_series.apply(lambda x: isinstance(x, str)).any():
                        bq_type = "STRING"

            schema.append(bigquery.SchemaField(col_name, bq_type))

        for field in schema:
            col = field.name
            if field.field_type == "DATE":
                try:
                    df[col] = pd.to_datetime(df[col], errors="coerce").dt.date
                except Exception as e:
                    print(f"⚠️ date column {col} transfer failed: {e}")
            elif field.field_type == "DATETIME":
                try:
                    df[col] = pd.to_datetime(df[col], errors="coerce")
                except Exception as e:
                    print(f"⚠️ time column {col} transfer failed: {e}")

        table_id = f"{dataset_id}.{table}"
        job_config = bigquery.LoadJobConfig(schema=schema, write_disposition="WRITE_TRUNCATE")
        job = bq_client.load_table_from_dataframe(df, table_id, job_config=job_config)
        job.result()
        print(f"✅ uploaded: {table}")