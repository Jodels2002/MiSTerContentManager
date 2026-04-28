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

# =========================
# 🧠 System Mapping (WICHTIG)
# =========================

SYSTEM_MAP = {
    "Nintendo - Nintendo Entertainment System": "NES",
    "Nintendo - Super Nintendo Entertainment System": "SNES",
    "Sega - Mega Drive - Genesis": "MEGADRIVE",
    "Sega - Game Gear": "GAMEGEAR",
    "Nintendo - Game Boy": "GAMEBOY",
    "Nintendo - Game Boy Advance": "GBA"
}

# =========================
# 📦 DAT Loader (libretro)
# =========================

def load_dats():
    for file in os.listdir(DAT_PATH):
        if file.endswith(".dat"):
            full_path = os.path.join(DAT_PATH, file)

            raw_name = file.replace(".dat", "")

            system = SYSTEM_MAP.get(raw_name, raw_name.upper())

            print(f"📦 Lade DAT: {raw_name} → {system}")

            databases[system] = parse_dat(full_path)

# =========================
# 🚀 Startup
# =========================

@app.on_event("startup")
def startup():
    init_db()
    load_dats()

# =========================
# 🔍 Scan
# =========================

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

# =========================
# 📚 Games API
# =========================

@app.get("/games")
def games():
    return get_games()
