#!/bin/bash

set -e

APP_NAME="MiSTerContentManager"
INSTALL_DIR="/opt/$APP_NAME"
REPO_URL="https://github.com/Jodels2002/MiSTerContentManager"  

echo "========================================="
echo " MiSTer Manager - System Installation"
echo "========================================="

# 🔐 Root prüfen
if [ "$EUID" -ne 0 ]; then
  echo "❌ Bitte als root oder mit sudo ausführen!"
  exit 1
fi

# 📦 Abhängigkeiten installieren
echo "📦 Installiere System-Abhängigkeiten..."

if command -v apt &> /dev/null; then
    apt update
    apt install -y python3 python3-venv python3-pip git \
                   libxml2-dev libxslt1-dev python3-dev build-essential
fi

if command -v pacman &> /dev/null; then
    pacman -Sy --noconfirm python python-pip git libxml2 libxslt base-devel
fi

if command -v dnf &> /dev/null; then
    dnf install -y python3 python3-pip git libxml2-devel libxslt-devel gcc
fi

# 📁 Zielordner vorbereiten
echo "📁 Installiere nach $INSTALL_DIR ..."

rm -rf "$INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR"

cd "$INSTALL_DIR"

# 🧪 Virtuelle Umgebung
echo "🧪 Erstelle Python venv..."
python3 -m venv venv

source venv/bin/activate

# 📦 Python Dependencies
echo "📦 Installiere Python Pakete..."
pip install --upgrade pip
pip install -r requirements.txt

# 📂 Runtime Ordner
mkdir -p data/dats
mkdir -p output/mgl
mkdir -p output/covers

# 🔐 Rechte setzen
echo "🔐 Setze Rechte..."
chown -R root:root "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

# 🚀 Startskript erstellen
echo "🚀 Erstelle Startkommando..."

cat << 'EOF' > /usr/local/bin/mister-manager
#!/bin/bash
cd /opt/mister-manager
source venv/bin/activate
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
EOF

chmod +x /usr/local/bin/mister-manager

echo "========================================="
echo " ✅ Installation abgeschlossen!"
echo "========================================="
echo ""
echo "👉 Starten mit:"
echo "   mister-manager"
echo ""
echo "👉 Webinterface:"
echo "   http://localhost:8000"
echo ""
echo "👉 DATs laden:"
echo "   http://localhost:8000/update-dats"
echo ""
