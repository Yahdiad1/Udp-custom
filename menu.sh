#!/bin/bash
# ============================================================
# YHDS VPN PREMIUM FULL INSTALLER + FULL MENU + TELEGRAM BOT
# Debian 11 – SSH/WS/XRAY/TROJAN/NGINX/UDP 1-65535
# ============================================================

clear
apt update -y
apt upgrade -y
apt install -y lolcat figlet unzip curl wget jq neofetch

# Disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sysctl -p

# Folder data
mkdir -p /etc/YHDS/system
mkdir -p /root/udp
touch /etc/YHDS/users.db

# Detect public IP
IP=$(curl -s ipinfo.io/ip)

# Banner
clear
echo -e "          ░█▀▀▀█ ░█▀▀▀█ ░█─── ─█▀▀█ ░█▀▀█   ░█─░█ ░█▀▀▄ ░█▀▀█ " | lolcat
echo -e "          ─▀▀▀▄▄ ░▀▀▀▄▄ ░█─── ░█▄▄█ ░█▀▀▄   ░█─░█ ░█─░█ ░█▄▄█ " | lolcat
echo -e "          ░█▄▄▄█ ░█▄▄▄█ ░█▄▄█ ░█─░█ ░█▄▄█   ░█▄▄▀ ░█▄▄▀ ░█─── " | lolcat
echo -e "                 YHDS VPN PREMIUM INSTALLER" | lolcat
sleep 3

# =======================
# Install XRAY
# =======================
bash -c "$(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)"

# =======================
# Install NGINX
# =======================
apt install nginx -y
systemctl enable nginx
systemctl start nginx

# =======================
# Install Trojan
# =======================
bash -c "$(curl -sL https://raw.githubusercontent.com/p4gefau1t/trojan-install/master/trojan.sh)"

# =======================
# Install UDP CUSTOM
# =======================
RAW="https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main"
wget "$RAW/udp-custom-linux-amd64" -O /root/udp/udp-custom
chmod +x /root/udp/udp-custom
wget "$RAW/config.json" -O /root/udp/config.json

cat <<EOF >/etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom YHDS
[Service]
User=root
ExecStart=/root/udp/udp-custom server
Restart=always
RestartSec=2
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

# =====================================================
# ================== FULL MENU SCRIPT =================
# =====================================================
cat <<'EOF' >/usr/local/bin/menu
#!/bin/bash
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'; NC='\e[0m'

DB_DIR="/etc/YHDS"
SYSTEM_DIR="/etc/YHDS/system"
UDP_DIR="/root/udp"
IP=$(curl -s ipinfo.io/ip)

status_service() {
    if systemctl is-active --quiet "$1"; then echo -e "${GREEN}ON${NC}"; else echo -e "${RED}OFF${NC}"; fi
}

create_user() {
    read -p "Username: " username
    read -p "Password: " password
    read -p "Expire (hari): " expire
    exp_date=$(date -d "+$expire days" +"%Y-%m-%d")
    echo "$username|$password|$exp_date" >> "$DB_DIR/users.db"

    # Telegram notif
    if [ -f "$DB_DIR/telegram.conf" ]; then
        source "$DB_DIR/telegram.conf"
        curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chatid" \
        -d text="🔔 *User Baru Dibuat*
👤 User: $username
🔑 Pass: $password
📅 Exp: $exp_date" >/dev/null
    fi

    clear
    echo -e "${GREEN}User berhasil dibuat!${NC}"
    echo ""
    echo "=== PAYLOAD SSH/WS ==="
    echo "GET /ws HTTP/1.1"
    echo "Host: $IP"
    echo "Upgrade: websocket"
    echo "User: $username"
    echo "Pass: $password"
    echo "==================="
    echo ""
    echo "=== PAYLOAD TROJAN ==="
    echo "trojan://$password@$IP:443"
    echo "==================="
    echo ""
}

create_udp_user() {
    echo "Buat akun UDP manual"
    read -p "Username: " uusername
    read -p "Password: " upassword
    read -p "Expire (hari): " uexpire
    exp_date=$(date -d "+$uexpire days" +"%Y-%m-%d")
    echo "$uusername|$upassword|$exp_date" >> "$DB_DIR/users.db"
    echo "User UDP berhasil dibuat!"
    echo "Payload UDP ready:"
    echo "$IP:$uusername:$upassword"
    echo ""
}

create_trojan_user() {
    echo "Buat akun Trojan manual"
    read -p "Username: " tusername
    read -p "Password: " tpassword
    read -p "Expire (hari): " texpire
    exp_date=$(date -d "+$texpire days" +"%Y-%m-%d")
    echo "$tusername|$tpassword|$exp_date" >> "$DB_DIR/users.db"
    echo "Payload Trojan ready:"
    echo "trojan://$tpassword@$IP:443"
    echo ""
}

create_trial_user() {
    read -p "Nama trial: " tusername
    password="trial123"
    exp_date=$(date -d "+1 days" +"%Y-%m-%d")
    echo "$tusername|$password|$exp_date" >> "$DB_DIR/users.db"
    echo "Trial user berhasil dibuat!"
    echo "Payload WS:"
    echo "GET /ws HTTP/1.1"
    echo "Host: $IP"
    echo "User: $tusername"
    echo "Pass: $password"
    echo "==================="
    echo ""
}

while true; do
clear
echo -e "          ░█▀▀▀█ ░█▀▀▀█ ░█─── ─█▀▀█ ░█▀▀█   ░█─░█ ░█▀▀▄ ░█▀▀█ " | lolcat
echo -e "          ─▀▀▀▄▄ ░▀▀▀▄▄ ░█─── ░█▄▄█ ░█▀▀▄   ░█─░█ ░█─░█ ░█▄▄█ " | lolcat
echo -e "          ░█▄▄▄█ ░█▄▄▄█ ░█▄▄█ ░█─░█ ░█▄▄█   ░█▄▄▀ ░█▄▄▀ ░█─── " | lolcat
echo -e "                   ${YELLOW}YHDS VPN PREMIUM MENU${NC}"
echo ""
echo -e "${BLUE}STATUS LAYANAN:${NC}"
echo -e "SSH     : $(status_service ssh)"
echo -e "WS      : $(status_service xray)"
echo -e "UDP     : $(status_service udp-custom)"
echo -e "Xray    : $(status_service xray)"
echo -e "Nginx   : $(status_service nginx)"
echo -e "Trojan  : $(status_service trojan)"
echo "===================================="
echo "1) Tambah User SSH/WS"
echo "2) Tambah User UDP"
echo "3) Tambah User Trojan"
echo "4) Tambah Trial"
echo "5) Hapus User"
echo "6) Daftar User"
echo "7) Remove Script"
echo "8) Torrent Blocker"
echo "9) Restart All Server"
echo "10) Set Telegram Bot"
echo "11) Keluar"
echo "===================================="
read -p "Pilih menu: " pilih

case $pilih in
    1) create_user ;;
    2) create_udp_user ;;
    3) create_trojan_user ;;
    4) create_trial_user ;;
    5) $SYSTEM_DIR/DelUser.sh ;;
    6) cat $DB_DIR/users.db ; read ;;
    7) $SYSTEM_DIR/RemoveScript.sh ;;
    8) $SYSTEM_DIR/torrent.sh ;;
    9) systemctl restart ssh nginx xray trojan udp-custom ; echo "Semua server direstart!"; sleep 2 ;;
    10)
        read -p "Token Bot: " token
        read -p "Chat ID: " chatid
        echo "token=$token" > $DB_DIR/telegram.conf
        echo "chatid=$chatid" >> $DB_DIR/telegram.conf
        echo "Bot disimpan!"
        sleep 2 ;;
    11) exit ;;
    *) echo "Salah"; sleep 1 ;;
esac
done
EOF

chmod +x /usr/local/bin/menu

# Auto menu saat login
if ! grep -q "/usr/local/bin/menu" /root/.bashrc; then
    echo "/usr/local/bin/menu" >> /root/.bashrc
fi

clear
echo -e "YHDS VPN PREMIUM selesai diinstall!" | lolcat
echo "Jalankan menu: menu"
echo "Close terminal → login lagi → menu muncul otomatis"
