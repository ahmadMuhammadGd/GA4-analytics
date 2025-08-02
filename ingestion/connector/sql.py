from ingestion.connector.connector import Connector
from sqlalchemy.engine import create_engine 
from sqlalchemy import inspect
import pandas as pd
from typing import Optional

class Sql(Connector):
    def __init__(self, connection_uri:str):
        self.connection = create_engine(connection_uri)
        self.dialect_name = self.connection.dialect.name

    def source_data(self, sql):
        raise NotImplementedError(f"this function hasn't been implemented yet")

    def _table_exists(self, table_name: str, schema: str = None) -> bool:
        inspector = inspect(self.connection)
        return table_name in inspector.get_table_names(schema=schema)
    
    def _qualify_table(self, schema:str, table_name:str):
        return f"{schema}.{table_name}" if schema else table_name
    
    def sink_data(self, connector:Connector, sql_text:str, table_name:str,
                target_sql_file:str, schema:str=None, incremental_column:Optional[str] = None):
        '''
        High risk of sql injection, but it's not the project's scope!
        '''
        filtering_stmt = 'where true'
        if_exists = 'replace'
        max_timestamp_query = '<First run, no `max_timestamp_query`>'
        if self.dialect_name == 'sqlite':
            schema = None
        
        if incremental_column and self._table_exists(table_name, schema):
            if_exists = 'append'
            max_timestamp_query = f'select max({incremental_column}) from {self._qualify_table(schema, table_name)}'
            max_incremental_column = pd.read_sql(max_timestamp_query, self.connection).iloc[0, 0]
            
            if not max_incremental_column:
                raise Exception(f'"{max_timestamp_query}" returns None')
            
            filtering_stmt = f"where {incremental_column} > {max_incremental_column}"
        
        sql_text = f'''
-- debug info
-- run mode: {if_exists}
-- max_timestamp_query: {max_timestamp_query}
-- filtering_stmt: {filtering_stmt}
with __src as (
    {sql_text}
) 
select * from __src
{filtering_stmt}
        '''
        
        with open(target_sql_file, 'w') as f:
            f.write(sql_text)
        
        df = connector.source_data(sql_text)
        
        print(f'extracted {len(df)} row from {connector}')
        
        df.to_sql(name=table_name, con=self.connection, schema=schema, if_exists=if_exists)