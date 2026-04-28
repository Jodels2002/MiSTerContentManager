from pathlib import Path
from .config import MGL_PATH

def generate_mgl(game):
    content = f"""<mistergamedescription>
    <name>{game['name']}</name>
    <rbf>_Console/{game['system']}</rbf>
    <file delay="0" type="f">{game['path']}</file>
</mistergamedescription>"""

    Path(MGL_PATH).mkdir(parents=True, exist_ok=True)

    filename = f"{game['name'].replace('/', '_')}.mgl"
    path = Path(MGL_PATH) / filename

    with open(path, "w") as f:
        f.write(content)
