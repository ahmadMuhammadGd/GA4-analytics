from pathlib import Path

def get(file_path: Path) -> str:
    with open(file_path, 'r') as f:
        return f.read()