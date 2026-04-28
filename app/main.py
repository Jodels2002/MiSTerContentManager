from fastapi import FastAPI
from .scanner import scan_games
from .dat_parser import parse_dat
from .matcher import match_all
from .database import init_db, insert_game, get_games
from .mgl import generate_mgl
from .config import ROMS_PATH, DAT_PATH
import os

app = FastAPI()

databases = {}

def load_dats():
    for file in os.listdir(DAT_PATH):
        if file.endswith(".dat"):
            system = file.replace(".dat", "").upper()
            databases[system] = parse_dat(os.path.join(DAT_PATH, file))

@app.on_event("startup")
def startup():
    init_db()
    load_dats()

@app.get("/scan")
def scan():
    results = []

    for game in scan_games(ROMS_PATH):
        match = match_all(game, databases)

        game.update(match)

        insert_game(game)

        if game["matched"]:
            generate_mgl(game)

        results.append(game)

    return {"scanned": len(results)}

@app.get("/games")
def games():
    return get_games()
