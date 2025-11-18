=== START INSTALL.SH ===
#!/bin/bash
# =====================================
# FULL INSTALLER YHDS VPN (Merged + Payload + Telegram notifications)
# - Uses creatuser as create-user script (plus wrapper Adduser.sh for compatibility)
# - Trojan payload format B (trojan://PASS@IP:443#USER)
# - Auto payload display, trial, telegram notif (mode D - super detailed)
# =====================================

set -euo pipefail

# --------- Helper warna ----------
RED='\e[31m'; GREEN='\e[32m'; BLUE='\e[34m'; YELLOW='\e[33m'; NC='\e[0m'

# --------- Update & tools ----------
apt update -y
apt upgrade -y
apt install -y lolcat figlet neofetch screenfetch unzip curl wget jq iproute2 nano

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
echo "        Installer YHDS VPN - Full Menu (with payload & Telegram)"
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
# Install trojan-go (binary) and service
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
# (we will create creatuser plus helpers)
# ------------------------------

# 1) common.sh : utilities (IP detect, print_payload, send_tele, service status)
cat > /etc/YHDS/system/common.sh <<'COMMON'
#!/bin/bash
# Common utilities for YHDS scripts
IP="$(curl -s ipv4.icanhazip.com || curl -s https://api.ipify.org || hostname -I | awk '{print $1}')"

print_payload() {
  USER="$1"; PASS="$2"; ACTIVE="$3"; CREATED="$4"; EXPIRE="$5"
  OVPN_PORT="${6:-81}"; UDP_PORTS="${7:-1-65535}"
  OHP_SSH="${8:-8686}"; OHP_OVPN="${9:-8787}"
  OVPN_TCP="${10:-1194}"; OVPN_UDP="${11:-2200}"
  BADVPN="${12:-7100, 7200, 7300}"

  CYAN="\e[36m"; YELLOW="\e[33m"; GREEN="\e[32m"; NC="\e[0m"

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━ INFORMATION ACCOUNT SSH OVPN ━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}Username      :${NC} ${USER}"
  echo -e "${YELLOW}Password      :${NC} ${PASS}"
  echo -e "${YELLOW}Limit Ip      :${NC} 100 Device"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}Domain/IP     :${NC} ${IP}"
  echo -e "${YELLOW}OpenSsh       :${NC} 22"
  echo -e "${YELLOW}Dropbear      :${NC} 109, 143"
  echo -e "${YELLOW}Ssl/Tls       :${NC} 443"
  echo -e "${YELLOW}Ssh WS Tls    :${NC} 443"
  echo -e "${YELLOW}Ssh Ws None Tls:${NC} 80"
  echo -e "${YELLOW}Ssh Udp Custom:${NC} ${UDP_PORTS}"
  echo -e "${YELLOW}Ohp Ssh       :${NC} ${OHP_SSH}"
  echo -e "${YELLOW}Ohp Ovpn      :${NC} ${OHP_OVPN}"
  echo -e "${YELLOW}Ovpn Tcp      :${NC} ${OVPN_TCP}"
  echo -e "${YELLOW}Ovpn Udp      :${NC} ${OVPN_UDP}"
  echo -e "${YELLOW}Badvpn Udp    :${NC} ${BADVPN}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  echo -e "${GREEN}SSH WS TLS  :${NC} ${IP}:443@${USER}:${PASS}"
  echo -e "${GREEN}SSH WS NONE TLS :${NC} ${IP}:80@${USER}:${PASS}"
  echo -e "${GREEN}SSH UDP CUSTOM :${NC} ${IP}:${UDP_PORTS}@${USER}:${PASS}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  echo -e "${YELLOW}PAYLOAD SSH WS :${NC}"
  echo -e "GET / HTTP/1.1[crlf]Host: ${IP}[crlf]Connection: Upgrade[crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  echo -e "${YELLOW}PAYLOAD ENHANCED :${NC}"
  echo -e "PATCH / HTTP/1.1[crlf]Host: ${IP}[crlf]Host: bug.com[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]HTTP/enhanced 200 Ok[crlf]"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  echo -e "${YELLOW}PAYLOAD SPECIAL :${NC}"
  echo -e "GET / HTTP/1.1[crlf]Host: [host][crlf][crlf][split]CF-RAY / HTTP/1.1[crlf]Host: ${IP}[crlf]Connection: Keep-Alive[crlf]Upgrade: websocket[crlf][crlf]"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  echo -e "${YELLOW}CONFIG OPENVPN :${NC} https://${IP}:${OVPN_PORT}/"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  echo -e "${YELLOW}Active    :${NC} ${ACTIVE}"
  echo -e "${YELLOW}Created   :${NC} ${CREATED}"
  echo -e "${YELLOW}Expired   :${NC} ${EXPIRE}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  echo -e "${YELLOW}TROJAN PAYLOAD (contoh):${NC}"
  echo -e "trojan://${PASS}@${IP}:443#${USER}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

send_tele() {
  MSG="$1"
  if [ -f /etc/YHDS/telegram.env ]; then
    source /etc/YHDS/telegram.env
    BOT="${BOT_TOKEN:-${BOT:-}}"
    CID="${CHAT_ID:-${CHAT:-}}"
    if [ -n "$BOT" ] && [ -n "$CID" ]; then
      curl -s -X POST "https://api.telegram.org/bot${BOT}/sendMessage" \
        -d chat_id="$CID" \
        -d parse_mode="Markdown" \
        -d text="$(echo -e "$MSG")" >/dev/null 2>&1 || true
    fi
  fi
}

get_services_status_md() {
  SVC="udp-custom xray nginx trojan-go"
  OUT=""
  for s in $SVC; do
    if systemctl is-active --quiet $s; then
      OUT="${OUT}\n• ${s}: ✅ ON"
    else
      OUT="${OUT}\n• ${s}: ❌ OFF"
    fi
  done
  echo -e "$OUT"
}
COMMON

chmod +x /etc/YHDS/system/common.sh

# 2) creatuser.sh - main create user script (the user said "creatuser")
cat > /etc/YHDS/system/creatuser.sh <<'CREAT'
#!/bin/bash
set -euo pipefail
source /etc/YHDS/system/common.sh || true

read -p "Masukkan username: " USER
read -p "Masukkan password: " PASS
read -p "Masukkan masa aktif (hari): " DAYS
EXPIRE=$(date -d "+$DAYS days" +"%Y-%m-%d")
CREATED=$(date +"%d %b, %Y")
ACTIVE="${DAYS} days"

# create system account (no shell)
useradd -M -N -s /bin/false "$USER" 2>/dev/null || true
echo "$USER:$PASS" | chpasswd 2>/dev/null || true

mkdir -p /etc/YHDS/system
echo "${USER}|${PASS}|${EXPIRE}|ON" >> /etc/YHDS/system/ssh-users.txt
echo "${USER}|${PASS}|${EXPIRE}|ON" >> /etc/YHDS/system/udp-users.txt
echo "${USER}|${PASS}|${EXPIRE}|ON" >> /etc/YHDS/system/trojan-users.txt

# display payload
print_payload "$USER" "$PASS" "$ACTIVE" "$CREATED" "$EXPIRE"

# telegram notif (super detailed)
SVC="$(get_services_status_md)"
MSG="🔥 *YHDS VPN - New Account Created*\n• User: \`${USER}\`\n• Pass: \`${PASS}\`\n• Active: \`${ACTIVE}\`\n• Created: \`${CREATED}\`\n• Expires: \`${EXPIRE}\`\n• IP: \`${IP}\`\n\n*Payload*\n• SSH WS TLS: \`${IP}:443@${USER}:${PASS}\`\n• TROJAN TLS: \`trojan://${PASS}@${IP}:443#${USER}\`\n\n*Service status:*${SVC}"
send_tele "$MSG"
CREAT

chmod +x /etc/YHDS/system/creatuser.sh

# 3) Adduser.sh wrapper (keamanan kompatibilitas - menu lama tetap panggil Adduser.sh)
cat > /etc/YHDS/system/Adduser.sh <<'WRAP'
#!/bin/bash
# Wrapper untuk backward compatibility : panggil creatuser
if [ -x /etc/YHDS/system/creatuser.sh ]; then
  /etc/YHDS/system/creatuser.sh
else
  echo "creatuser script tidak ditemukan."
fi
WRAP
chmod +x /etc/YHDS/system/Adduser.sh

# 4) CreateTrojan.sh (already present but overwrite with notif)
cat > /etc/YHDS/system/CreateTrojan.sh <<'CT'
#!/bin/bash
set -euo pipefail
source /etc/YHDS/system/common.sh || true

read -p "Masukkan username untuk Trojan: " USER
read -p "Masukkan password untuk Trojan: " PASS
read -p "Masukkan masa aktif (hari): " DAYS
read -p "Pilih port Trojan (443 atau 80): " PORT
EXPIRE=$(date -d "+$DAYS days" +"%Y-%m-%d")
CREATED=$(date +"%d %b, %Y")
ACTIVE="${DAYS} days"

mkdir -p /etc/YHDS/system
echo "${USER}|${PASS}|${EXPIRE}|ON|${PORT}" >> /etc/YHDS/system/trojan-users.txt

if [ -f /etc/trojan-go/config.json ] && command -v jq >/dev/null 2>&1; then
  jq --arg p "$PASS" '.password += [$p]' /etc/trojan-go/config.json > /etc/trojan-go/config.json.tmp && mv /etc/trojan-go/config.json.tmp /etc/trojan-go/config.json || true
  systemctl restart trojan-go >/dev/null 2>&1 || true
fi

print_payload "$USER" "$PASS" "$ACTIVE" "$CREATED" "$EXPIRE"

SVC="$(get_services_status_md)"
MSG="🔐 *YHDS VPN - New Trojan Account*\n• User: \`${USER}\`\n• Pass: \`${PASS}\`\n• Port: \`${PORT}\`\n• Active: \`${ACTIVE}\`\n• Expires: \`${EXPIRE}\`\n• IP: \`${IP}\`\n\n*Trojan Payload*\n\`trojan://${PASS}@${IP}:${PORT}#${USER}\`\n\n*Service status:*${SVC}"
send_tele "$MSG"
CT
chmod +x /etc/YHDS/system/CreateTrojan.sh

# 5) CreateTrial.sh (overwrite with notif)
cat > /etc/YHDS/system/CreateTrial.sh <<'CTR'
#!/bin/bash
set -euo pipefail
source /etc/YHDS/system/common.sh || true

read -p "Pilih jenis trial (ssh/udp/trojan/xray): " TYPE
read -p "Masukkan username trial: " USER
PASS="trial$(date +%s | tail -c 4)"
read -p "Masukkan durasi trial (menit): " MINS
EXPIRE=$(date -d "+$MINS minutes" +"%Y-%m-%d %H:%M")
CREATED=$(date +"%d %b, %Y")
ACTIVE="${MINS} minutes"

mkdir -p /etc/YHDS/system

case "$TYPE" in
  ssh)
    useradd -M -N -s /bin/false "$USER" 2>/dev/null || true
    echo "$USER:$PASS" | chpasswd 2>/dev/null || true
    echo "${USER}|${PASS}|${EXPIRE}|ON" >> /etc/YHDS/system/ssh-users.txt
    print_payload "$USER" "$PASS" "$ACTIVE" "$CREATED" "$EXPIRE"
    MSG="🔥 *YHDS VPN - Trial SSH Created*\n• User: \`${USER}\`\n• Pass: \`${PASS}\`\n• Expire: \`${EXPIRE}\`\n• IP: \`${IP}\`\n\n*Payload*\n• ssh: \`ssh ${USER}@${IP} -p 22\`"
    send_tele "$MSG"
    ;;
  udp)
    echo "${USER}|${PASS}|${EXPIRE}|ON" >> /etc/YHDS/system/udp-users.txt
    print_payload "$USER" "$PASS" "$ACTIVE" "$CREATED" "$EXPIRE"
    MSG="🔥 *YHDS VPN - Trial UDP Created*\n• User: \`${USER}\`\n• Pass: \`${PASS}\`\n• Expire: \`${EXPIRE}\`\n• IP: \`${IP}\`\n\n*Payload*\n• UDP: \`${IP}:1-65535@${USER}:${PASS}\`"
    send_tele "$MSG"
    ;;
  trojan)
    echo "${USER}|${PASS}|${EXPIRE}|ON|443" >> /etc/YHDS/system/trojan-users.txt
    if [ -f /etc/trojan-go/config.json ] && command -v jq >/dev/null 2>&1; then
      jq --arg p "$PASS" '.password += [$p]' /etc/trojan-go/config.json > /etc/trojan-go/config.json.tmp && mv /etc/trojan-go/config.json.tmp /etc/trojan-go/config.json || true
      systemctl restart trojan-go >/dev/null 2>&1 || true
    fi
    print_payload "$USER" "$PASS" "$ACTIVE" "$CREATED" "$EXPIRE"
    MSG="🔐 *YHDS VPN - Trial Trojan Created*\n• User: \`${USER}\`\n• Pass: \`${PASS}\`\n• Expire: \`${EXPIRE}\`\n• IP: \`${IP}\`\n\n*Trojan Payload*\n\`trojan://${PASS}@${IP}:443#${USER}\`"
    send_tele "$MSG"
    ;;
  xray)
    UUID=$(cat /proc/sys/kernel/random/uuid)
    echo "${USER}|${UUID}|${EXPIRE}|ON" >> /etc/YHDS/system/xray-users.txt
    print_payload "$USER" "${UUID}" "$ACTIVE" "$CREATED" "$EXPIRE"
    VMESS=$(echo "{\"v\":\"2\",\"ps\":\"$USER\",\"add\":\"$IP\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/\",\"tls\":\"tls\"}" | base64 -w0)
    echo "vmess://${VMESS}"
    MSG="🔷 *YHDS VPN - Trial Xray Created*\n• User: \`${USER}\`\n• UUID: \`${UUID}\`\n• Expire: \`${EXPIRE}\`\n• IP: \`${IP}\`\n\n*VMESS Payload*\n\`vmess://${VMESS}\`"
    send_tele "$MSG"
    ;;
  *)
    echo "Tipe tidak dikenal: pilih ssh/udp/trojan/xray"
    ;;
esac
CTR
chmod +x /etc/YHDS/system/CreateTrial.sh

# 6) DelUser.sh (overwrite to send notif)
cat > /etc/YHDS/system/DelUser.sh <<'DEL'
#!/bin/bash
set -euo pipefail
source /etc/YHDS/system/common.sh || true

read -p "Masukkan username yang akan dihapus: " USER
if id "$USER" >/dev/null 2>&1; then
  userdel -r "$USER" 2>/dev/null || true
fi
sed -i "/^${USER}|/d" /etc/YHDS/system/ssh-users.txt 2>/dev/null || true
sed -i "/^${USER}|/d" /etc/YHDS/system/udp-users.txt 2>/dev/null || true
sed -i "/^${USER}|/d" /etc/YHDS/system/trojan-users.txt 2>/dev/null || true

MSG="🗑️ *YHDS VPN - Account Deleted*\n• User: \`${USER}\`\n• IP: \`${IP}\`\n• Time: \`$(date '+%Y-%m-%d %H:%M:%S')\`"
send_tele "$MSG"

echo "User $USER dihapus (jika ada)."
DEL
chmod +x /etc/YHDS/system/DelUser.sh

# 7) DashboardStatus.sh (keep functionality, but ensure exists)
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

# 8) InstallBot.sh (keeps storing BOT_TOKEN & CHAT_ID)
cat > /etc/YHDS/system/InstallBot.sh <<'IB'
#!/bin/bash
read -p "Masukkan BOT TOKEN: " BOT_TOKEN
read -p "Masukkan CHAT ID: " CHAT_ID
mkdir -p /etc/YHDS
echo "BOT_TOKEN=${BOT_TOKEN}" > /etc/YHDS/telegram.env
echo "CHAT_ID=${CHAT_ID}" >> /etc/YHDS/telegram.env
chmod 600 /etc/YHDS/telegram.env
echo "Telegram config disimpan."
IB
chmod +x /etc/YHDS/system/InstallBot.sh

# 9) SendDashboard.sh - send full status (used by cron)
cat > /etc/YHDS/system/SendDashboard.sh <<'SDB'
#!/bin/bash
source /etc/YHDS/system/common.sh || true

SSH_COUNT=$(wc -l < /etc/YHDS/system/ssh-users.txt 2>/dev/null || echo 0)
UDP_COUNT=$(wc -l < /etc/YHDS/system/udp-users.txt 2>/dev/null || echo 0)
TR_COUNT=$(wc -l < /etc/YHDS/system/trojan-users.txt 2>/dev/null || echo 0)
XR_COUNT=$(wc -l < /etc/YHDS/system/xray-users.txt 2>/dev/null || echo 0)

SVC="$(get_services_status_md)"
MSG="📊 *YHDS VPN - Dashboard Report*\n• IP: \`${IP}\`\n\n*Services:*${SVC}\n\n*Users:*\n• SSH: \`${SSH_COUNT}\`\n• UDP: \`${UDP_COUNT}\`\n• Trojan: \`${TR_COUNT}\`\n• Xray: \`${XR_COUNT}\`\n\n_Time: \`$(date '+%Y-%m-%d %H:%M:%S')\`_"
send_tele "$MSG"
SDB
chmod +x /etc/YHDS/system/SendDashboard.sh

# 10) Cronjob for SendDashboard every 30 minutes (root)
( crontab -l 2>/dev/null | grep -v "/etc/YHDS/system/SendDashboard.sh" ) 2>/dev/null > /tmp/crontab.YHDS || true
echo "*/30 * * * * /etc/YHDS/system/SendDashboard.sh >/dev/null 2>&1" >> /tmp/crontab.YHDS
crontab /tmp/crontab.YHDS
rm -f /tmp/crontab.YHDS

# 11) Move old menu if exists to backup, then create menu (same structure as you provided)
[ -f /usr/local/bin/menu ] && mv /usr/local/bin/menu /usr/local/bin/menu.bak.$(date +%s) || true

cat > /usr/local/bin/menu <<'MENU'
#!/bin/bash
# YHDS VPN Main Menu (full) - Modified only to ensure compat with creatuser wrapper

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
    1) /etc/YHDS/system/creatuser.sh; echo ""; read -p "Tekan Enter...";;
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
       # send telegram notif about restart (if configured)
       if [ -f /etc/YHDS/system/common.sh ]; then
         source /etc/YHDS/system/common.sh || true
         send_tele "*YHDS VPN - Services Restarted*\nAdmin restarted all services at $(date '+%Y-%m-%d %H:%M:%S')"
       fi
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

# ensure menu autostart on login (root)
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
echo "Langkah selanjutnya:"
echo "1) Jalankan 'menu'"
echo "2) Pilih 8) Install Bot Telegram Notifikasi -> masukkan BOT_TOKEN dan CHAT_ID"
echo "3) Tes Create User / Create Trojan / Create Trial -> payload akan tampil dan Telegram akan menerima notifikasi (jika token diisi)."
echo ""
echo "Atau logout & login kembali untuk auto-start menu."
=== END INSTALL.SH ===
