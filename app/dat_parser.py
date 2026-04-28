import re

def parse_dat(dat_path):
    db = {}

    with open(dat_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    # Spiele splitten
    games = content.split("game (")

    for g in games:
        sha1_match = re.findall(r"sha1\s+\"([A-Fa-f0-9]{40})\"", g)
        name_match = re.findall(r'name\s+"([^"]+)"', g)

        if sha1_match and name_match:
            sha1 = sha1_match[0]
            name = name_match[0]

            db[sha1] = {
                "name": name
            }

    return db
