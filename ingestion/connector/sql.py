from ingestion.connector.connector import Connector
from sqlalchemy.engine import create_engine

class Sql(Connector):
    def __init__(self, connection_uri:str):
        self.connection = create_engine(connection_uri)
    
    def sink_data(self, connector:Connector, sql_text:str, table_name:str, schema=None):
        df = connector.source_data(sql_text)
        df.to_sql(name=table_name, con=self.connection, schema=schema, if_exists='replace')