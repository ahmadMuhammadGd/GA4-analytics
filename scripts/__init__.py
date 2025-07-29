from dotenv import load_dotenv
from pathlib import Path
import os

config_dir_path = Path(__file__).parent / 'config' 
entrypoint_config_file_path = config_dir_path / '.env'
load_dotenv(entrypoint_config_file_path)

env_file_path = config_dir_path / os.environ["environment"]
print(f"\n__init__.py: Loading '{env_file_path}")
load_dotenv(env_file_path)