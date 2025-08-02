from abc import ABC, abstractmethod
import pandas as pd

class Connector(ABC):
    @abstractmethod
    def source_data(self, sql:str) -> pd.DataFrame:
        """get's data from the source"""
        raise NotImplementedError
    
    @abstractmethod
    def sink_data(self, df: pd.DataFrame, table_name: str, **kwargs) -> None:
        """sinks data to the destination"""
        raise NotImplementedError