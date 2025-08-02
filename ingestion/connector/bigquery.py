from ingestion.connector.connector import Connector
from google.cloud import bigquery
from pathlib import Path

class BigQuery(Connector):
    def __init__(self, json_credentials:Path):
        self.json_credentials = Path(json_credentials) if not isinstance(json_credentials, Path) else json_credentials
        self.client = bigquery.Client.from_service_account_json(json_credentials_path=self.json_credentials)
    
    def source_data(self, sql:str):
        return self.client.query_and_wait(sql).to_dataframe()
    
    def sink_data(self, df, table_name, **kwargs):
        raise NotImplementedError(f"this function hasn't been implemented yet")