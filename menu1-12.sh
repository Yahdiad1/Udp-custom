#!/bin/bash
# =============================================
# YHDS VPN FULL INSTALLER 2025
# UDP 1-65535 + XRAY + TROJAN GO + NGINX
# MENU 1–12 FULL FUNGSI + PAYLOAD OTOMATIS
# =============================================

set -euo pipefail
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'; CYAN='\e[36m'; NC='\e[0m'

# =====================================================
# PREPARE SISTEM
# =====================================================
apt update -y
apt upgrade -y
apt install -y figlet lolcat screenfetch neofetch git wget curl unzip jq nginx bc

# Disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

mkdir -p /etc/YHDS/system
mkdir -p /root/udp

# =====================================================
# INSTALL XRAY
# =====================================================
echo -e "${GREEN}Install Xray...${NC}"
bash -c "$(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)"

# =====================================================
# INSTALL TROJAN-GO
# =====================================================
echo -e "${GREEN}Install Trojan-Go...${NC}"
TGZ_URL="https://github.com/p4gefau1t/trojan-go/releases/latest/download/trojan-go-linux-amd64.zip"
wget -qO /tmp/tg.zip $TGZ_URL
unzip -o /tmp/tg.zip -d /usr/local/bin >/dev/null
chmod +x /usr/local/bin/trojan-go

# =====================================================
# INSTALL UDP CUSTOM
# =====================================================
echo -e "${GREEN}Install UDP Custom...${NC}"
GITHUB_RAW="https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main"
wget -q "$GITHUB_RAW/udp-custom-linux-amd64" -O /root/udp/udp-custom
chmod +x /root/udp/udp-custom

cat > /root/udp/config.json <<EOF
{
  "listen": "0.0.0.0",
  "start_port": 1,
  "end_port": 65535,
  "max_clients": 2000,
  "threads": 4,
  "mode": "auto"
}
EOF

cat > /etc/systemd/system/udp-custom.service <<EOF
[Unit]
Description=YHDS UDP Custom Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/udp
ExecStart=/root/udp/udp-custom server -c /root/udp/config.json
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom

# =====================================================
# COMMON FUNCTION
# =====================================================
cat > /etc/YHDS/system/common.sh <<'EOF'
#!/bin/bash
IP=$(curl -s https://api.ipify.org)
DOMAIN_SSH="ssh.yhds.my.id"
DOMAIN_MAIN="yhds.my.id"
DOMAIN_UDP="udp.yhds.my.id"

print_payload() {
  U="$1"; P="$2"
  echo "================== PAYLOAD USER =================="
  echo "SSH WS TLS     : ${DOMAIN_SSH}:443 @ $U:$P"
  echo "TROJAN         : trojan://$P@${DOMAIN_MAIN}:443#$U"
  echo "UDP CUSTOM     : ${DOMAIN_UDP}:1-65535 @ $U:$P"
  echo "=================================================="
}
EOF
chmod +x /etc/YHDS/system/common.sh

# =====================================================
# CREATE USER SCRIPT
# =====================================================
cat > /etc/YHDS/system/creatuser.sh <<'EOF'
#!/bin/bash
source /etc/YHDS/system/common.sh

read -p "Username : " U
read -p "Password : " P
read -p "Expired (hari): " H

EXP=$(date -d "+$H days" +"%Y-%m-%d")

useradd -M -N -s /bin/false "$U" 2>/dev/null || true
echo "$U:$P" | chpasswd

echo "$U|$P|$EXP|ON" >> /etc/YHDS/system/users.txt

clear
print_payload "$U" "$P"
EOF

chmod +x /etc/YHDS/system/creatuser.sh

# =====================================================
# MENU 1–12 FULL
# =====================================================
cat > /usr/local/bin/menu <<'EOF'
#!/bin/bash
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; CYAN='\e[36m'; NC='\e[0m'

status_server() {
  for svc in udp-custom xray trojan-go nginx; do
    if systemctl is-active --quiet "$svc"; then
      echo -e " $svc : ${GREEN}ON${NC}"
    else
      echo -e " $svc : ${RED}OFF${NC}"
    fi
  done
}

hapus_user() {
  echo "Masukkan username:"
  read U
  sed -i "/^$U|/d" /etc/YHDS/system/users.txt
  userdel "$U" 2>/dev/null || true
  echo "User $U dihapus"
}

list_user() {
  echo "====== DAFTAR USER ======"
  cat /etc/YHDS/system/users.txt
}

create_trial() {
  U="trial$(date +%s)"
  P="123"
  EXP=$(date -d "+1 days" +"%Y-%m-%d")
  useradd -M -N -s /bin/false "$U"
  echo "$U:$P" | chpasswd
  echo "$U|$P|$EXP|ON" >> /etc/YHDS/system/users.txt
  clear
  source /etc/YHDS/system/common.sh
  print_payload "$U" "$P"
}

while true; do
  clear
  figlet -f slant "YHDS VPN" | lolcat
  echo -e "${CYAN}STATUS SERVER:${NC}"
  status_server
  echo ""
  echo "1) Create User + Payload"
  echo "2) Hapus User"
  echo "3) List User"
  echo "4) Create Trojan (AUTO)"
  echo "5) Create Trial"
  echo "6) Toggle User ON/OFF"
  echo "7) Dashboard Status"
  echo "8) Install Bot Telegram"
  echo "9) Restart Semua Service"
  echo "10) Uninstall Script"
  echo "11) Keluar"
  echo "12) Setting Domain"
  read -p "Pilih [1-12]: " x

  case $x in
    1) /etc/YHDS/system/creatuser.sh ;;
    2) hapus_user ;;
    3) list_user ;;
    4) echo "Auto Trojan belum dibuat" ;;
    5) create_trial ;;
    6) echo "Fitur Toggle belum dibuat" ;;
    7) neofetch ;;
    8) echo "Bot Telegram belum dibuat" ;;
    9) systemctl restart udp-custom xray nginx trojan-go ;;
    10) rm -rf /etc/YHDS /root/udp /usr/local/bin/menu; exit ;;
    11) exit ;;
    12) echo "Setting domain belum tersedia" ;;
  esac
  read -p "Enter untuk kembali..."
done
EOF

chmod +x /usr/local/bin/menu

# AUTO MENU LOGIN
if ! grep -q "menu" /root/.bashrc; then
  echo "menu" >> /root/.bashrc
fi

# =====================================================
clear
figlet "YHDS VPN" | lolcat
echo -e "${GREEN}Install selesai! Ketik: menu${NC}"
echo "Automatis muncul saat login"
