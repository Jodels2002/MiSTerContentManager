#!/bin/bash

echo "=== MiSTer Companion Setup startet ==="

# -----------------------------

# CONFIG – HIER ANPASSEN

# -----------------------------

MISTER_IP="192.168.178.140"
PI_USER=$(whoami)

# -----------------------------

# SYSTEM UPDATE

# -----------------------------

echo "[1/6] System Update..."
sudo apt update && sudo apt upgrade -y

# -----------------------------

# BASIS PAKETE

# -----------------------------

echo "[2/6] Installiere Basis-Pakete..."
sudo apt install -y git python3 python3-pip rsync curl cifs-utils

# -----------------------------

# MISTER COMMANDER INSTALLATION

# -----------------------------

echo "[3/6] Installiere MiSTer Commander..."
cd /opt
sudo git clone https://github.com/misteraddons/mister_commander.git
cd mister_commander
sudo pip3 install -r requirements.txt

# Systemd Service erstellen

echo "[3.1] Erstelle Service..."
sudo bash -c 'cat > /etc/systemd/system/mister-commander.service <<EOF
[Unit]
Description=MiSTer Commander Web Interface
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/mister_commander/server.py
Restart=always
User='$PI_USER'

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable mister-commander
sudo systemctl start mister-commander

# -----------------------------

# SYNCTHING INSTALLATION

# -----------------------------

echo "[4/6] Installiere Syncthing..."
sudo apt install -y syncthing

sudo systemctl enable syncthing@$PI_USER
sudo systemctl start syncthing@$PI_USER

# -----------------------------

# NETDATA INSTALLATION

# -----------------------------

echo "[5/6] Installiere Netdata..."
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait

# -----------------------------

# SSH ALIAS

# -----------------------------

echo "[6/6] SSH Alias einrichten..."
echo "alias mister='ssh root@$MISTER_IP'" >> ~/.bashrc

# -----------------------------

# SMB MOUNT VORBEREITUNG

# -----------------------------

echo "[OPTIONAL] SMB Mount vorbereiten..."
sudo mkdir -p /mnt/mister

sudo bash -c 'cat >> /etc/fstab <<EOF
//'$MISTER_IP'/fat /mnt/mister cifs username=root,password=1,iocharset=utf8,vers=1.0 0 0
EOF'

echo ""
echo "=== INSTALLATION FERTIG ==="
echo ""
echo "MiSTer Commander: http://$(hostname -I | awk '{print $1}'):8000"
echo "Syncthing: http://$(hostname -I | awk '{print $1}'):8384"
echo "Netdata: http://$(hostname -I | awk '{print $1}'):19999"
echo ""
echo "Neustart empfohlen!"
