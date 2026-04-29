#!/bin/bash
set -euo pipefail

echo "=== MiSTer Web UI CLEAN INSTALL ==="

# -----------------------------

# CONFIG

# -----------------------------

MISTER_IP="192.168.178.140"
PI_USER=$(whoami)
INSTALL_DIR="/opt/mister-web"
SERVICE_NAME="mister-web"

# -----------------------------

# STOP & REMOVE OLD INSTALL

# -----------------------------

echo "[0/8] Alte Installation entfernen (falls vorhanden)..."

sudo systemctl stop $SERVICE_NAME 2>/dev/null || true
sudo systemctl disable $SERVICE_NAME 2>/dev/null || true
sudo rm -f /etc/systemd/system/$SERVICE_NAME.service

sudo rm -rf $INSTALL_DIR

# -----------------------------

# SYSTEM UPDATE

# -----------------------------

echo "[1/8] System Update..."
sudo apt update && sudo apt upgrade -y

# -----------------------------

# PACKAGES

# -----------------------------

echo "[2/8] Installiere Pakete..."
sudo apt install -y python3 python3-venv python3-pip git

# -----------------------------

# INSTALL DIR

# -----------------------------

echo "[3/8] Installationsverzeichnis..."
sudo mkdir -p $INSTALL_DIR
sudo chown $PI_USER:$PI_USER $INSTALL_DIR
cd $INSTALL_DIR

# -----------------------------

# PYTHON ENV

# -----------------------------

echo "[4/8] Python venv..."
python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install flask paramiko

# -----------------------------

# APP

# -----------------------------

echo "[5/8] Web App erstellen..."

cat > app.py <<EOF
from flask import Flask, render_template, redirect
import paramiko
import json

app = Flask(__name__)

MISTER_IP = "192.168.178.140"

def ssh_cmd(cmd):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(MISTER_IP, username="root", password="1")
    stdin, stdout, stderr = ssh.exec_command(cmd)
    result = stdout.read().decode()
    ssh.close()
    return result

# -----------------------------
# SPIELE STATISTIK (NEU)
# -----------------------------
def get_game_stats():
    try:
        output = ssh_cmd("ls -1 /media/fat/games")
        systems = [x for x in output.split("\n") if x.strip()]

        data = {}

        for sys in systems:
            count = ssh_cmd(f"find /media/fat/games/{sys} -type f | wc -l")
            try:
                data[sys] = int(count.strip())
            except:
                data[sys] = 0

        return data

    except:
        return {"Error": 1}

# -----------------------------
# DASHBOARD
# -----------------------------
@app.route("/")
def index():
    stats = get_game_stats()
    return render_template("index.html", stats=json.dumps(stats))

# -----------------------------
@app.route("/reboot")
def reboot():
    ssh_cmd("reboot")
    return "MiSTer rebooting..."

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
EOF

# -----------------------------

# TEMPLATE

# -----------------------------

mkdir -p templates

cat > templates/index.html <<'EOF'

<!DOCTYPE html>

<html>
<head>
    <title>MiSTer Web UI</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial; background:#111; color:#eee; padding:20px; }
        h1 { color:#0af; }
        .game { padding:12px; margin:10px 0; background:#222; border-radius:10px; }
        a { color:#0af; text-decoration:none; }
        .btn { display:inline-block; margin-top:5px; padding:6px 10px; background:#0af; color:white; border-radius:5px; }
    </style>
</head>
<body>

<h1>🎮 MiSTer Web UI</h1>

<p><a class="btn" href="/reboot">Reboot</a></p>

{% for game in games %}

<div class="game">
    <div>{{ game }}</div>
    <a class="btn" href="/start/{{ game }}">▶️ Start</a>
</div>
{% endfor %}

</body>
</html>
EOF

# -----------------------------

# SYSTEMD SERVICE

# -----------------------------

echo "[6/8] systemd Service..."

sudo bash -c "cat > /etc/systemd/system/$SERVICE_NAME.service <<EOL
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
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# -----------------------------

# DONE

# -----------------------------

echo "[7/8] Fertig!"

IP_ADDR=$(hostname -I | awk '{print $1}')

echo ""
echo "=== Zugriff ==="
echo "http://$IP_ADDR:8000"
echo ""
echo "MiSTer IP: $MISTER_IP"
echo ""
echo "Login MiSTer: root / 1"
echo ""
echo "🚀 Installation abgeschlossen"
