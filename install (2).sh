#!/bin/bash

# =====================================
# FULL INSTALLER YHDS VPN (UDP + SSH/WS + Xray + Nginx + Trojan-go)
# - Menambah: Create Trojan (443 & 80), Trial semua akun
# - Setelah create tampilkan payload
# =====================================

set -euo pipefail

# --------- Helper warna ----------
RED='\e[31m'; GREEN='\e[32m'; BLUE='\e[34m'; YELLOW='\e[33m'; NC='\e[0m'

# --------- Update & tools ----------
apt update -y
apt upgrade -y
apt install -y lolcat figlet neofetch screenfetch unzip curl wget jq iproute2

# --------- Disable IPv6 ----------
echo "Menonaktifkan IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
grep -qxF "net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf || echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
grep -qxF "net.ipv6.conf.default.disable_ipv6 = 1" /etc/sysctl.conf || echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
grep -qxF "net.ipv6.conf.lo.disable_ipv6 = 1" /etc/sysctl.conf || echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p >/dev/null 2>&1 || true

# --------- Prepare directories ----------
rm -rf /root/udp || true
mkdir -p /root/udp
mkdir -p /etc/YHDS/system

# --------- Banner ----------
clear
figlet -f slant "YHDS VPN" | lolcat
echo ""
echo "        Installer YHDS VPN - Full Menu"
sleep 1

# --------- Timezone ----------
ln -fs /usr/share/zoneinfo/Asia/Colombo /etc/localtime || true

# ------------------------------
# Install Xray (official installer)
# ------------------------------
echo -e "${YELLOW}Install Xray...${NC}"
bash -c "$(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)" >/dev/null 2>&1 || echo "Xray install warning, lanjut..."

# ------------------------------
# Install Nginx
# ------------------------------
echo -e "${YELLOW}Install Nginx...${NC}"
apt install -y nginx >/dev/null 2>&1 || echo "nginx install warning"

systemctl enable nginx >/dev/null 2>&1 || true
systemctl start nginx >/dev/null 2>&1 || true

# ------------------------------
# Install trojan-go (binary release) and create service
# ------------------------------
echo -e "${YELLOW}Install trojan-go...${NC}"
TGZ_URL="https://github.com/p4gefau1t/trojan-go/releases/latest/download/trojan-go-linux-amd64.zip"
TMPZIP="/tmp/trojan-go.zip"
if wget -q -O "$TMPZIP" "$TGZ_URL"; then
  unzip -o "$TMPZIP" -d /usr/local/bin/ >/dev/null 2>&1 || true
  chmod +x /usr/local/bin/trojan-go || true
else
  echo "Gagal download trojan-go binary, lanjut tanpa trojan-go."
fi

# default minimal config (user can override)
mkdir -p /etc/trojan-go
cat > /etc/trojan-go/config.json <<'TGCONF'
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 443,
  "password": ["YHDS2025"],
  "ssl": {
    "cert": "/etc/ssl/certs/ssl-cert-snakeoil.pem",
    "key": "/etc/ssl/private/ssl-cert-snakeoil.key"
  }
}
TGCONF

# create systemd service if binary exists
if [ -x /usr/local/bin/trojan-go ]; then
  cat > /etc/systemd/system/trojan-go.service <<'SRV'
[Unit]
Description=trojan-go
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/trojan-go -config /etc/trojan-go/config.json
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
SRV

  systemctl daemon-reload
  systemctl enable trojan-go >/dev/null 2>&1 || true
  systemctl restart trojan-go >/dev/null 2>&1 || true
fi

# ------------------------------
# Download UDP Custom binary + config from your repo
# ------------------------------
GITHUB_RAW="https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main"

echo -e "${YELLOW}Download UDP Custom binary...${NC}"
wget -q "$GITHUB_RAW/udp-custom-linux-amd64" -O /root/udp/udp-custom || echo "Gagal download udp-custom"
chmod +x /root/udp/udp-custom || true

echo -e "${YELLOW}Download UDP config...${NC}"
wget -q "$GITHUB_RAW/config.json" -O /root/udp/config.json || echo "Gagal download config.json"
chmod 644 /root/udp/config.json || true

# systemd service for udp-custom
cat > /etc/systemd/system/udp-custom.service <<'UDPSRV'
[Unit]
Description=YHDS VPN UDP Custom
After=network.target

[Service]
User=root
Type=simple
ExecStart=/root/udp/udp-custom server
WorkingDirectory=/root/udp/
Restart=always
RestartSec=2s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
UDPSRV

systemctl daemon-reload
systemctl enable udp-custom >/dev/null 2>&1 || true
systemctl restart udp-custom >/dev/null 2>&1 || true

# ------------------------------
# Create supporting scripts in /etc/YHDS/system
# - Adduser.sh (create SSH/WS + UDP + trojan entry)
# - DelUser.sh
# - Userlist.sh
# - CreateTrojan.sh
# - CreateTrial.sh
# - ToggleUser.sh (edit status)
# - DashboardStatus.sh
# ------------------------------

# Adduser.sh
cat > /etc/YHDS/system/Adduser.sh <<'ADD'
#!/bin/bash
# Tambah user SSH/WS + UDP entry + trojan entry (password)
set -euo pipefail
read -p "Masukkan username: " USER
read -p "Masukkan password: " PASS
read -p "Masukkan masa aktif (hari): " DAYS
EXPIRE=$(date -d "+$DAYS days" +"%Y-%m-%d")
# create system user (disable shell)
useradd -M -N -s /bin/false "$USER" 2>/dev/null || useradd -M -s /bin/false "$USER" 2>/dev/null || true
echo "$USER:$PASS" | chpasswd 2>/dev/null || true

# record SSH/WS user
mkdir -p /etc/YHDS/system
echo "${USER}|${PASS}|${EXPIRE}|ON" >> /etc/YHDS/system/ssh-users.txt

# add UDP user record
echo "${USER}|${PASS}|${EXPIRE}|ON" >> /etc/YHDS/system/udp-users.txt

# add trojan record (password used by trojan-go)
echo "${USER}|${PASS}|${EXPIRE}|ON" >> /etc/YHDS/system/trojan-users.txt

IP=$(curl -sS https://api.ipify.org || hostname -I | awk '{print $1}')
# payloads
echo ""
echo "=== AKUN DIBUAT ==="
echo "User   : $USER"
echo "Pass   : $PASS"
echo "Expire : $EXPIRE"
echo ""
echo "=== PAYLOAD SSH/WS ==="
echo "Host: $IP"
echo "Port: 22 (SSH) / 80/443 (WS sesuai konfigurasi nginx)"
echo "Username: $USER"
echo "Password: $PASS"
echo ""
echo "=== TROJAN (contoh) ==="
echo "trojan://$PASS@$IP:443#${USER}"
echo ""
ADD
chmod +x /etc/YHDS/system/Adduser.sh

# DelUser.sh
cat > /etc/YHDS/system/DelUser.sh <<'DEL'
#!/bin/bash
set -euo pipefail
read -p "Masukkan username yang akan dihapus: " USER
# remove system user
if id "$USER" >/dev/null 2>&1; then
  userdel -r "$USER" 2>/dev/null || true
fi
# remove from records
sed -i "/^${USER}|/d" /etc/YHDS/system/ssh-users.txt 2>/dev/null || true
sed -i "/^${USER}|/d" /etc/YHDS/system/udp-users.txt 2>/dev/null || true
sed -i "/^${USER}|/d" /etc/YHDS/system/trojan-users.txt 2>/dev/null || true
echo "User $USER dihapus (jika ada)."
DEL
chmod +x /etc/YHDS/system/DelUser.sh

# Userlist.sh
cat > /etc/YHDS/system/Userlist.sh <<'UL'
#!/bin/bash
echo "=== Daftar SSH/WS User ==="
if [ -f /etc/YHDS/system/ssh-users.txt ]; then
  column -t -s '|' /etc/YHDS/system/ssh-users.txt || cat /etc/YHDS/system/ssh-users.txt
else
  echo "Tidak ada user SSH/WS"
fi
echo ""
echo "=== Daftar UDP User ==="
if [ -f /etc/YHDS/system/udp-users.txt ]; then
  column -t -s '|' /etc/YHDS/system/udp-users.txt || cat /etc/YHDS/system/udp-users.txt
else
  echo "Tidak ada user UDP"
fi
echo ""
echo "=== Daftar Trojan User ==="
if [ -f /etc/YHDS/system/trojan-users.txt ]; then
  column -t -s '|' /etc/YHDS/system/trojan-users.txt || cat /etc/YHDS/system/trojan-users.txt
else
  echo "Tidak ada user Trojan"
fi
UL
chmod +x /etc/YHDS/system/Userlist.sh

# CreateTrojan.sh - manual create trojan account with chosen port (443 or 80)
cat > /etc/YHDS/system/CreateTrojan.sh <<'CT'
#!/bin/bash
set -euo pipefail
read -p "Masukkan username untuk Trojan: " USER
read -p "Masukkan password untuk Trojan: " PASS
read -p "Masukkan masa aktif (hari): " DAYS
read -p "Pilih port Trojan (443 atau 80): " PORT
EXPIRE=$(date -d "+$DAYS days" +"%Y-%m-%d")
mkdir -p /etc/YHDS/system
# record
echo "${USER}|${PASS}|${EXPIRE}|ON|${PORT}" >> /etc/YHDS/system/trojan-users.txt
# update trojan-go config: append password if needed
if [ -f /etc/trojan-go/config.json ]; then
  # try to update password array (best-effort)
  if grep -q '"password"' /etc/trojan-go/config.json 2>/dev/null; then
    # naive insertion: replace array with new including PASS
    EXISTING=$(jq -r '.password' /etc/trojan-go/config.json 2>/dev/null || echo '[]')
    # build jq array update
    jq --arg p "$PASS" '.password += [$p]' /etc/trojan-go/config.json > /etc/trojan-go/config.json.tmp && mv /etc/trojan-go/config.json.tmp /etc/trojan-go/config.json
  fi
fi

IP=$(curl -sS https://api.ipify.org || hostname -I | awk '{print $1}')
echo ""
echo "=== TROJAN CREATED ==="
echo "User   : $USER"
echo "Pass   : $PASS"
echo "Expire : $EXPIRE"
echo "Port   : $PORT"
echo ""
echo "Payload Trojan (basic):"
echo "trojan://$PASS@$IP:$PORT#${USER}"
echo ""
CT
chmod +x /etc/YHDS/system/CreateTrojan.sh

# CreateTrial.sh - create trial for SSH/UDP/Trojan/Xray (short)
cat > /etc/YHDS/system/CreateTrial.sh <<'CTR'
#!/bin/bash
set -euo pipefail
read -p "Pilih jenis trial (ssh/udp/trojan/xray): " TYPE
read -p "Masukkan username trial: " USER
PASS="trial$(date +%s | tail -c 4)"
read -p "Masukkan durasi trial (menit): " MINS
EXPIRE=$(date -d "+$MINS minutes" +"%Y-%m-%d %H:%M")
mkdir -p /etc/YHDS/system
case "$TYPE" in
  ssh)
    # create system user temporary
    useradd -M -N -s /bin/false "$USER" 2>/dev/null || true
    echo "$USER:$PASS" | chpasswd 2>/dev/null || true
    echo "${USER}|${PASS}|${EXPIRE}|ON" >> /etc/YHDS/system/ssh-users.txt
    IP=$(curl -sS https://api.ipify.org || hostname -I | awk '{print $1}')
    echo ""
    echo "=== TRIAL SSH CREATED ==="
    echo "User: $USER"
    echo "Pass: $PASS"
    echo "Expire: $EXPIRE"
    echo "Payload:"
    echo "ssh $USER@$IP -p 22"
    ;;
  udp)
    echo "${USER}|${PASS}|${EXPIRE}|ON" >> /etc/YHDS/system/udp-users.txt
    IP=$(curl -sS https://api.ipify.org || hostname -I | awk '{print $1}')
    echo ""
    echo "=== TRIAL UDP CREATED ==="
    echo "User: $USER"
    echo "Pass: $PASS"
    echo "Expire: $EXPIRE"
    echo "Payload UDP (contoh):"
    echo "User:$USER Pass:$PASS Host:$IP"
    ;;
  trojan)
    echo "${USER}|${PASS}|${EXPIRE}|ON|443" >> /etc/YHDS/system/trojan-users.txt
    # attempt to add password to trojan-go config
    if [ -f /etc/trojan-go/config.json ]; then
      jq --arg p "$PASS" '.password += [$p]' /etc/trojan-go/config.json > /etc/trojan-go/config.json.tmp && mv /etc/trojan-go/config.json.tmp /etc/trojan-go/config.json || true
      systemctl restart trojan-go >/dev/null 2>&1 || true
    fi
    IP=$(curl -sS https://api.ipify.org || hostname -I | awk '{print $1}')
    echo ""
    echo "=== TRIAL TROJAN CREATED ==="
    echo "User: $USER"
    echo "Pass: $PASS"
    echo "Expire: $EXPIRE"
    echo "Payload Trojan:"
    echo "trojan://$PASS@$IP:443#${USER}"
    ;;
  xray)
    # For Xray, we'll create a UUID and show vmess sample payload (basic)
    UUID=$(cat /proc/sys/kernel/random/uuid)
    echo "${USER}|${UUID}|${EXPIRE}|ON" >> /etc/YHDS/system/xray-users.txt
    IP=$(curl -sS https://api.ipify.org || hostname -I | awk '{print $1}')
    echo ""
    echo "=== TRIAL XRAY CREATED ==="
    echo "User: $USER"
    echo "UUID: $UUID"
    echo "Expire: $EXPIRE"
    echo "Payload VMESS (example):"
    echo "vmess://$(echo "{\"v\":\"2\",\"ps\":\"$USER\",\"add\":\"$IP\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/\",\"tls\":\"tls\"}" | base64 -w0)"
    ;;
  *)
    echo "Tipe tidak dikenal: pilih ssh/udp/trojan/xray"
    ;;
esac
CTR
chmod +x /etc/YHDS/system/CreateTrial.sh

# ToggleUser.sh - open editor to change ON/OFF (simple)
cat > /etc/YHDS/system/ToggleUser.sh <<'TOG'
#!/bin/bash
set -euo pipefail
echo "Pilih file user untuk toggle:"
echo "1) SSH users"
echo "2) UDP users"
echo "3) Trojan users"
read -p "Pilihan [1-3]: " F
case "$F" in
  1) FILE=/etc/YHDS/system/ssh-users.txt ;;
  2) FILE=/etc/YHDS/system/udp-users.txt ;;
  3) FILE=/etc/YHDS/system/trojan-users.txt ;;
  *) echo "Pilihan invalid"; exit 1 ;;
esac
if [ ! -f "$FILE" ]; then
  echo "File $FILE tidak ditemukan."
  exit 1
fi
echo "Edit kolom status (ON/OFF). Format: user|pass|expire|ON"
nano "$FILE"
echo "Selesai edit."
TOG
chmod +x /etc/YHDS/system/ToggleUser.sh

# DashboardStatus.sh
cat > /etc/YHDS/system/DashboardStatus.sh <<'DB'
#!/bin/bash
RED='\e[31m'; GREEN='\e[32m'; NC='\e[0m'
echo "=== STATUS SERVICE ==="
for s in udp-custom xray nginx trojan-go; do
  if systemctl is-active --quiet $s; then
    echo -e "$s : ${GREEN}ON${NC}"
  else
    echo -e "$s : ${RED}OFF${NC}"
  fi
done
echo ""
echo "=== AKUN (SSH) ==="
[ -f /etc/YHDS/system/ssh-users.txt ] && column -t -s '|' /etc/YHDS/system/ssh-users.txt || echo "Tidak ada"
echo ""
echo "=== AKUN (UDP) ==="
[ -f /etc/YHDS/system/udp-users.txt ] && column -t -s '|' /etc/YHDS/system/udp-users.txt || echo "Tidak ada"
echo ""
echo "=== AKUN (Trojan) ==="
[ -f /etc/YHDS/system/trojan-users.txt ] && column -t -s '|' /etc/YHDS/system/trojan-users.txt || echo "Tidak ada"
DB
chmod +x /etc/YHDS/system/DashboardStatus.sh

# InstallBot.sh (simple store token/chat id)
cat > /etc/YHDS/system/InstallBot.sh <<'IB'
#!/bin/bash
read -p "Masukkan BOT TOKEN: " BOT_TOKEN
read -p "Masukkan CHAT ID: " CHAT_ID
mkdir -p /etc/YHDS
echo "BOT_TOKEN=$BOT_TOKEN" > /etc/YHDS/telegram.env
echo "CHAT_ID=$CHAT_ID" >> /etc/YHDS/telegram.env
echo "Telegram config disimpan."
IB
chmod +x /etc/YHDS/system/InstallBot.sh

# Move old menu if exists to backup
[ -f /usr/local/bin/menu ] && mv /usr/local/bin/menu /usr/local/bin/menu.bak.$(date +%s) || true

# ------------------------------
# Create main menu (/usr/local/bin/menu)
# ------------------------------
cat > /usr/local/bin/menu <<'MENU'
#!/bin/bash
# YHDS VPN Main Menu (full)

RED='\e[31m'; GREEN='\e[32m'; BLUE='\e[34m'; YELLOW='\e[33m'; NC='\e[0m'

status() {
  for service in udp-custom xray nginx trojan-go; do
    if systemctl is-active --quiet $service; then
      echo -e "$service : ${GREEN}ON${NC}"
    else
      echo -e "$service : ${RED}OFF${NC}"
    fi
  done
}

while true; do
  clear
  figlet -f slant "YHDS VPN" | lolcat
  echo ""
  echo -e "${YELLOW}Status Server:${NC}"
  status
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${YELLOW}1) Create User (SSH/WS + UDP + Trojan)${NC}"
  echo -e "${YELLOW}2) Hapus User${NC}"
  echo -e "${YELLOW}3) Daftar User${NC}"
  echo -e "${YELLOW}4) Create Trojan (manual port 443/80)${NC}"
  echo -e "${YELLOW}5) Create Trial (ssh/udp/trojan/xray)${NC}"
  echo -e "${YELLOW}6) Toggle ON/OFF Akun${NC}"
  echo -e "${YELLOW}7) Dashboard Status & Tampilkan Akun${NC}"
  echo -e "${YELLOW}8) Install Bot Telegram Notifikasi${NC}"
  echo -e "${YELLOW}9) Restart Semua Server (UDP/Xray/Nginx/Trojan)${NC}"
  echo -e "${YELLOW}10) Remove Script / Uninstall${NC}"
  echo -e "${YELLOW}11) Keluar${NC}"
  echo -e "${BLUE}========================================${NC}"
  read -p "Pilih menu [1-11]: " opt

  case "$opt" in
    1) /etc/YHDS/system/Adduser.sh; echo ""; read -p "Tekan Enter...";;
    2) /etc/YHDS/system/DelUser.sh; echo ""; read -p "Tekan Enter...";;
    3) /etc/YHDS/system/Userlist.sh; echo ""; read -p "Tekan Enter...";;
    4) /etc/YHDS/system/CreateTrojan.sh; echo ""; read -p "Tekan Enter...";;
    5) /etc/YHDS/system/CreateTrial.sh; echo ""; read -p "Tekan Enter...";;
    6) /etc/YHDS/system/ToggleUser.sh; echo ""; read -p "Tekan Enter...";;
    7) /etc/YHDS/system/DashboardStatus.sh; echo ""; read -p "Tekan Enter...";;
    8) /etc/YHDS/system/InstallBot.sh; echo ""; read -p "Tekan Enter...";;
    9)
       echo "Restarting services..."
       for s in udp-custom xray nginx trojan-go; do
         if systemctl list-units --full -all | grep -q "^$s"; then
           systemctl restart $s >/dev/null 2>&1 || true
         fi
       done
       echo "Selesai."; read -p "Tekan Enter..."
       ;;
    10)
       read -p "Yakin hapus semua script YHDS? (y/n): " YN
       if [[ "$YN" == "y" ]]; then
         systemctl stop udp-custom >/dev/null 2>&1 || true
         systemctl disable udp-custom >/dev/null 2>&1 || true
         rm -rf /etc/YHDS /root/udp /usr/local/bin/menu
         echo "Dihapus."
         exit 0
       fi
       ;;
    11) exit 0 ;;
    *) echo "Pilihan salah"; sleep 1 ;;
  esac
done
MENU

chmod +x /usr/local/bin/menu

# ensure menu autostart on login
if ! grep -q "/usr/local/bin/menu" /root/.bashrc 2>/dev/null; then
  echo "/usr/local/bin/menu" >> /root/.bashrc
fi

# start services if present
systemctl daemon-reload || true
systemctl start udp-custom >/dev/null 2>&1 || true
systemctl enable udp-custom >/dev/null 2>&1 || true

clear
figlet -f slant "YHDS VPN" | lolcat
echo ""
echo -e "${GREEN}Install selesai!${NC}"
echo "Jalankan perintah: menu"
echo "Atau logout & login kembali untuk auto-start menu."
