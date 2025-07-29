import os
from pathlib import Path
from scripts.utils import creds
from ingestion.connector import Sql, BigQuery
from jinja2 import Environment, FileSystemLoader

# === Variables === #
bigquery_creds_path = os.environ['bigquery_creds_path']
postgres_creds_path = os.environ['postgres_creds_path']
postgres_uri = creds.get(postgres_creds_path)['db_uri']
sql_directory = Path('scripts/sql')
target_directory = Path('target')
os.makedirs(target_directory, exist_ok=True)

# === Setting Environment Variables === #
env = Environment(loader=FileSystemLoader(sql_directory))
env.globals['environment'] = os.environ['environment']

# === Connectors === #
bigquery_connector = BigQuery(bigquery_creds_path)
postgres_connector = Sql(postgres_uri)

# === Ingestion Queries === #
query_templates_list = [
    'ga_events.sql',
]

# === Execution === #
if __name__ == '__main__':
    for template in query_templates_list:
        sql = env.get_template(template).render()
        table_name = Path(template).stem
        
        target_sql_file = target_directory  / f'{Path(__file__).stem}.sql'
        with open(target_sql_file, 'w') as f:
            f.write(sql)
    
        try:
            postgres_connector.sink_data(
                connector=bigquery_connector,
                sql_text=sql,
                table_name=table_name, 
                schema='raw_stg'
            )
        except Exception as e:
            raise Exception(f"{e}\n\nCheck target sql file at => {target_sql_file}")
        