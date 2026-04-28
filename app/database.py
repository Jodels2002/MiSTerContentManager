import sqlite3
from .config import DB_PATH

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE IF NOT EXISTS games (
        id INTEGER PRIMARY KEY,
        name TEXT,
        system TEXT,
        path TEXT,
        sha1 TEXT UNIQUE,
        matched INTEGER
    )
    """)

    conn.commit()
    conn.close()

def insert_game(game):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
    INSERT OR REPLACE INTO games (name, system, path, sha1, matched)
    VALUES (?, ?, ?, ?, ?)
    """, (
        game["name"],
        game["system"],
        game["path"],
        game["hash"],
        int(game["matched"])
    ))

    conn.commit()
    conn.close()

def get_games():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("SELECT * FROM games")
    rows = cur.fetchall()
    conn.close()
    return rows
