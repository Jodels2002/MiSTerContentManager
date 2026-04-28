#!/bin/bash
set -e

APP_NAME="MiSTerContentManager"
INSTALL_DIR="/opt/$APP_NAME"
REPO_URL="https://github.com/Jodels2002/MiSTerContentManager.git"  
CONFIG_FILE="$INSTALL_DIR/app/config.py"

export DEBIAN_FRONTEND=noninteractive

echo "========================================="
echo " MiSTer Manager - Debian 13 Installer"
echo "========================================="

# 🔐 Root prüfen
if [ "$EUID" -ne 0 ]; then
  echo "❌ Bitte mit sudo oder als root ausführen!"
  exit 1
fi

# =========================
# 📦 Debian 13 Pakete
# =========================

echo "📦 Installiere Abhängigkeiten (Debian 13)..."

apt update

apt install -y \
  python3 \
  python3-venv \
  python3-pip \
  git \
  curl \
  ca-certificates \
  whiptail \
  libxml2-dev \
  libxslt1-dev \
  build-essential

# =========================
# 📁 Installation
# =========================

echo "📁 Installiere nach $INSTALL_DIR ..."

if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ Vorhandene Installation wird ersetzt..."
    rm -rf "$INSTALL_DIR"
fi

git clone "$REPO_URL" "$INSTALL_DIR"
cd "$INSTALL_DIR"

# =========================
# 🧪 Python venv
# =========================

echo "🧪 Erstelle virtuelle Umgebung..."

python3 -m venv venv
source venv/bin/activate

echo "⬆️ Upgrade pip..."
pip install --upgrade pip wheel setuptools

echo "📦 Installiere Python Pakete..."
pip install -r requirements.txt

# =========================
# 📂 Runtime Ordner
# =========================

mkdir -p data/dats
mkdir -p output/mgl
mkdir -p output/covers

# =========================
# 📂 ROM Pfad Auswahl (whiptail)
# =========================

DEFAULT_PATH="/media/fat/games"

ROM_PATH=$(whiptail --title "MiSTer ROM Pfad" \
  --inputbox "Bitte Pfad zum 'games' Ordner eingeben:" \
  10 70 "$DEFAULT_PATH" \
  3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    echo "❌ Installation abgebrochen"
    exit 1
fi

# Trim (wichtig!)
ROM_PATH=$(echo "$ROM_PATH" | xargs)

if [ ! -d "$ROM_PATH" ]; then
    whiptail --title "Fehler" \
      --msgbox "Ordner existiert nicht:\n$ROM_PATH" 10 60
    exit 1
fi

echo "📂 Verwende ROM Pfad: $ROM_PATH"

# =========================
# ⚙️ config.py patchen
# =========================

echo "⚙️ Setze ROM Pfad in config.py..."

sed -i "s|ROMS_PATH = .*|ROMS_PATH = \"$ROM_PATH\"|g" "$CONFIG_FILE"

# =========================
# 🔐 Rechte
# =========================

echo "🔐 Setze Berechtigungen..."

chown -R root:root "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

# =========================
# 🚀 Startkommando
# =========================

echo "🚀 Erstelle CLI Kommando..."

cat << 'EOF' > /usr/local/bin/mister-manager
#!/bin/bash
cd /opt/mister-manager
source venv/bin/activate
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
EOF

chmod +x /usr/local/bin/mister-manager

# =========================
# ✅ Fertig
# =========================

echo "========================================="
echo " ✅ Installation erfolgreich!"
echo "========================================="
echo ""
echo "👉 ROM Pfad:"
echo "   $ROM_PATH"
echo ""
echo "👉 Start:"
echo "   mister-manager"
echo ""
echo "👉 Browser:"
echo "   http://localhost:8000"
echo ""
echo "👉 DATs laden:"
echo "   http://localhost:8000/update-dats"
echo ""
