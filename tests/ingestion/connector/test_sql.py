import pytest
import pandas as pd
from unittest.mock import MagicMock, patch
from ingestion.connector.sql import Sql
from ingestion.connector.connector import Connector


@pytest.fixture
def mock_connector():
    mock = MagicMock(spec=Connector)
    mock.source_data.return_value = pd.DataFrame({'col': [1, 2]})
    return mock


# @patch("ingestion.connector.sql.create_engine")
@patch("ingestion.connector.sql.inspect")
@patch("pandas.read_sql")
def test_sink_data_first_run(mock_read_sql, mock_inspect, mock_connector, tmp_path):
    # Table does NOT exist => first run (replace)
    mock_inspect.return_value.get_table_names.return_value = []
    sql = Sql("sqlite:///:memory:")
    sql_text = "select * from dummy"
    target_file = tmp_path / "first_run.sql"

    sql.sink_data(
        connector=mock_connector,
        sql_text=sql_text,
        table_name="dummy_table",
        target_sql_file=str(target_file),
        schema="public",
        incremental_column="event_timestamp"
    )

    with open(target_file) as f:
        content = f.read()
        assert "run mode: replace" in content
        assert "First run" in content
        assert "where true" in content

    mock_read_sql.assert_not_called()
    mock_connector.source_data.assert_called_once()


# @patch("ingestion.connector.sql.create_engine")
@patch("ingestion.connector.sql.inspect")
@patch("pandas.read_sql")
def test_sink_data_incremental_run(mock_read_sql, mock_inspect, mock_connector, tmp_path):
    # Table exists + has max timestamp => append
    mock_inspect.return_value.get_table_names.return_value = ['dummy_table']
    mock_read_sql.return_value = pd.DataFrame({"event_timestamp": [123]})
    sql = Sql("sqlite:///:memory:")
    sql_text = "select * from dummy"
    target_file = tmp_path / "incremental_run.sql"

    sql.sink_data(
        connector=mock_connector,
        sql_text=sql_text,
        table_name="dummy_table",
        target_sql_file=str(target_file),
        schema="public",
        incremental_column="event_timestamp"
    )

    with open(target_file) as f:
        content = f.read()
        assert "run mode: append" in content
        assert "event_timestamp > 123" in content

    mock_read_sql.assert_called_once()
    mock_connector.source_data.assert_called_once()
