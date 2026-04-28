import hashlib
from pathlib import Path
from .config import ROM_EXTENSIONS

def sha1_file(path):
    h = hashlib.sha1()
    with open(path, 'rb') as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()

def scan_games(root):
    for file in Path(root).rglob("*"):
        if file.suffix.lower() in ROM_EXTENSIONS:
            yield {
                "path": str(file),
                "hash": sha1_file(file),
                "name": file.stem
            }
