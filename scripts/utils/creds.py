import json 
from pathlib import Path

def get(file_path: Path) -> json:
    with open(file_path, 'r') as f:
        return json.load(f)