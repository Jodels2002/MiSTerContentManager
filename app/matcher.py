def match_all(scan_entry, databases):
    sha1 = scan_entry["hash"]

    for system, db in databases.items():
        if sha1 in db:
            return {
                "matched": True,
                "system": system,
                "name": db[sha1]["name"]
            }

    return {
        "matched": False,
        "system": "unknown",
        "name": scan_entry["name"]
    }
