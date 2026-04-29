#!/bin/bash

set -e

echo "=== MiSTer Web UI Installation startet ==="

# -----------------------------

# CONFIG

# -----------------------------

MISTER_IP="192.168.178.140"
PI_USER=$(whoami)
INSTALL_DIR="/opt/mister-web"

# -----------------------------

# SYSTEM UPDATE

# -----------------------------

echo "[1/7] System Update..."
sudo apt update && sudo apt upgrade -y

# -----------------------------

# BASIS PAKETE

# -----------------------------

echo "[2/7] Installiere Pakete..."
sudo apt install -y python3 python3-venv python3-pip git

# -----------------------------

# INSTALLATIONSVERZEICHNIS

# -----------------------------

echo "[3/7] Verzeichnis vorbereiten..."
sudo mkdir -p $INSTALL_DIR
sudo chown $PI_USER:$PI_USER $INSTALL_DIR
cd $INSTALL_DIR

# -----------------------------

# PYTHON VENV

# -----------------------------

echo "[4/7] Python Umgebung..."
python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install flask paramiko

# -----------------------------

# APP ERSTELLEN

# -----------------------------

echo "[5/7] Web App erstellen..."

cat > app.py <<EOF
from flask import Flask, render_template, redirect
import paramiko

app = Flask(__name__)

MISTER_IP = "$MISTER_IP"

def ssh_cmd(cmd):
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(MISTER_IP, username="root", password="1")
stdin, stdout, stderr = ssh.exec_command(cmd)
result = stdout.read().decode()
ssh.close()
return result

def list_games():
try:
output = ssh_cmd("find /media/fat/games -type f")
lines = output.split("\n")
return [l for l in lines if l]
except:
return ["Fehler beim Laden der Spieleliste"]

@app.route("/")
def index():
games = list_games()
return render_template("index.html", games=games)

@app.route("/start/[path:game](path:game)")
def start(game):
ssh_cmd(f'/media/fat/Scripts/run_game.sh "{game}"')
return redirect("/")

@app.route("/reboot")
def reboot():
ssh_cmd("reboot")
return "MiSTer rebooting..."

if **name** == "**main**":
app.run(host="0.0.0.0", port=8000)
EOF

# -----------------------------

# HTML TEMPLATE

# -----------------------------

mkdir -p templates

cat > templates/index.html << 'EOF'

<!DOCTYPE html>

<html>
<head>
    <title>MiSTer Web UI</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: Arial;
            background: #111;
            color: #eee;
            padding: 20px;
        }
        h1 { color: #0af; }
        .game {
            padding: 12px;
            margin: 10px 0;
            background: #222;
            border-radius: 10px;
        }
        a {
            color: #0af;
            text-decoration: none;
        }
        .btn {
            display: inline-block;
            margin-top: 5px;
            padding: 6px 10px;
            background: #0af;
            color: white;
            border-radius: 5px;
        }
    </style>
</head>
<body>

<h1>🎮 MiSTer Web UI</h1>

<p><a href="/reboot" class="btn">Reboot</a></p>

{% for game in games %}

<div class="game">
    <div>{{ game }}</div>
    <a href="/start/{{ game }}" class="btn">▶️ Start</a>
</div>
{% endfor %}

</body>
</html>
EOF

# -----------------------------

# SYSTEMD SERVICE

# -----------------------------

echo "[6/7] Service einrichten..."

sudo bash -c "cat > /etc/systemd/system/mister-web.service <<EOL
[Unit]
Description=MiSTer Web UI
After=network.target

[Service]
User=$PI_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOL"

sudo systemctl daemon-reload
sudo systemctl enable mister-web
sudo systemctl restart mister-web

# -----------------------------

# FERTIG

# -----------------------------

echo "[7/7] Fertig!"
IP_ADDR=$(hostname -I | awk '{print $1}')

echo ""
echo "=== Zugriff ==="
echo "Web UI:  http://$IP_ADDR:8000"
echo ""
echo "Hinweis:"
echo "- SSH auf dem MiSTer aktivieren"
echo "- Login: root / 1"
echo ""
echo "Optional:"
echo "nano /media/fat/Scripts/run_game.sh"
echo ""
echo "Fertig 🚀"
