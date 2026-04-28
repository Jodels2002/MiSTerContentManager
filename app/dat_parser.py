from lxml import etree

def parse_dat(dat_path):
    tree = etree.parse(dat_path)
    root = tree.getroot()

    db = {}

    for game in root.findall("game"):
        game_name = game.get("name")

        for rom in game.findall("rom"):
            sha1 = rom.get("sha1")
            if sha1:
                db[sha1] = {
                    "name": game_name
                }

    return db
