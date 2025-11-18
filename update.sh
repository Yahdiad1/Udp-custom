#!/usr/bin/env bash
# =========================================================
# YHDS VPN PREMIUM - FULL INSTALLER + MENU
# Debian 11
# =========================================================

set -euo pipefail

# ===================== UPDATE & TOOLS =====================
apt update -y
apt upgrade -y
apt install -y lolcat figlet unzip curl wget jq neofetch

# Disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -p

# ===================== FOLDER & DATABASE =====================
DB="/etc/yhds/users.db"
TG_CONF="/etc/yhds/telegram.conf"
UDP_DIR="/root/udp"
SYSTEM_DIR="/etc/yhds/system"

mkdir -p "$SYSTEM_DIR" "$UDP_DIR"
touch "$DB"

# ===================== BANNER =====================
banner(){
clear
echo -e ""
echo -e "        \e[35m███████╗██╗  ██╗██████╗ ███████╗\e[0m"
echo -e "        \e[35m██╔════╝██║  ██║██╔══██╗██╔════╝\e[0m"
echo -e "        \e[35m███████╗███████║██████╔╝█████╗  \e[0m"
echo -e "        \e[35m╚════██║██╔══██║██╔══██╗██╔══╝  \e[0m"
echo -e "        \e[35m███████║██║  ██║██║  ██║███████╗\e[0m"
echo -e "        \e[35m╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝\e[0m"
echo -e "              \e[92mYHDS VPN PREMIUM\e[0m"
echo -e ""
}

# ===================== COLORS =====================
red(){ echo -e "\e[31m$1\e[0m"; }
green(){ echo -e "\e[32m$1\e[0m"; }
yellow(){ echo -e "\e[33m$1\e[0m"; }
blue(){ echo -e "\e[34m$1\e[0m"; }

# ===================== INSTALL SERVICES =====================
echo "Install Xray..."
bash -c "$(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)"

echo "Install Nginx..."
apt install nginx -y
systemctl enable nginx
systemctl start nginx

echo "Install Trojan..."
bash -c "$(curl -sL https://raw.githubusercontent.com/p4gefau1t/trojan-install/master/trojan.sh)"

# ===================== INSTALL UDP CUSTOM =====================
RAW="https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main"
wget "$RAW/udp-custom-linux-amd64" -O "$UDP_DIR/udp-custom"
chmod +x "$UDP_DIR/udp-custom"
wget "$RAW/config.json" -O "$UDP_DIR/config.json"

cat <<EOF >/etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom YHDS
[Service]
User=root
ExecStart=$UDP_DIR/udp-custom server
Restart=always
RestartSec=2
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

# ===================== FULL MENU =====================
cat <<'EOF' >/usr/local/bin/menu
#!/usr/bin/env bash
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'; NC='\e[0m'

DB="/etc/yhds/users.db"
TG_CONF="/etc/yhds/telegram.conf"
UDP_DIR="/root/udp"
SYSTEM_DIR="/etc/yhds/system"

svc_status(){
    systemctl is-active "$1" &>/dev/null && echo -e "${GREEN}ON${NC}" || echo -e "${RED}OFF${NC}"
}

tg_send(){
    [[ ! -f "$TG_CONF" ]] && return
    source "$TG_CONF"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}&text=${1}" >/dev/null 2>&1
}

create_user(){
    read -p "Username: " username
    read -p "Password: " password
    read -p "Expire (hari): " expire
    exp_date=$(date -d "+$expire days" +"%Y-%m-%d")
    echo "$username|$password|$exp_date" >> "$DB"
    tg_send "🔔 User Baru Dibuat\n👤 $username\n🔑 $password\n📅 $exp_date"
    clear
    echo -e "${GREEN}User berhasil dibuat!${NC}"
    echo "Payload WS:"
    echo "GET /ws HTTP/1.1"
    echo "Host: yourdomain.com"
    echo "User: $username"
    echo "Pass: $password"
}

create_udp(){
    read -p "Username UDP: " u_user
    read -p "Password UDP: " u_pass
    read -p "Expire (hari): " u_exp
    u_exp_date=$(date -d "+$u_exp days" +"%Y-%m-%d")
    echo "$u_user|$u_pass|$u_exp_date" >> "$DB"
    echo -e "${GREEN}UDP User berhasil dibuat!${NC}"
    echo "Payload UDP: udp://$u_user:$u_pass@IP:PORT"
}

create_trojan(){
    read -p "Username Trojan: " t_user
    read -p "Password Trojan: " t_pass
    read -p "Expire (hari): " t_exp
    t_exp_date=$(date -d "+$t_exp days" +"%Y-%m-%d")
    echo "$t_user|$t_pass|$t_exp_date" >> "$DB"
    echo -e "${GREEN}Trojan User berhasil dibuat!${NC}"
    echo "Payload Trojan: trojan://$t_user:$t_pass@IP:443"
}

create_trial(){
    read -p "Username Trial: " tr_user
    tr_pass="trial"
    tr_exp_date=$(date -d "+1 days" +"%Y-%m-%d")
    echo "$tr_user|$tr_pass|$tr_exp_date" >> "$DB"
    echo -e "${GREEN}Trial User dibuat!${NC}"
    echo "Payload Trial: GET /ws HTTP/1.1 Host: yourdomain.com User:$tr_user Pass:$tr_pass"
}

while true; do
clear
echo -e "          ░█▀▀▀█ ░█▀▀▀█ ░█─── ─█▀▀█ ░█▀▀█   ░█─░█ ░█▀▀▄ ░█▀▀█ " | lolcat
echo -e "          ─▀▀▀▄▄ ░▀▀▀▄▄ ░█─── ░█▄▄█ ░█▀▀▄   ░█─░█ ░█─░█ ░█▄▄█ " | lolcat
echo -e "          ░█▄▄▄█ ░█▄▄▄█ ░█▄▄█ ░█─░█ ░█▄▄█   ░█▄▄▀ ░█▄▄▀ ░█─── " | lolcat
echo "===================================="
echo -e "SSH     : $(svc_status ssh)"
echo -e "WS      : $(svc_status xray)"
echo -e "UDP     : $(svc_status udp-custom)"
echo -e "Xray    : $(svc_status xray)"
echo -e "Nginx   : $(svc_status nginx)"
echo -e "Trojan  : $(svc_status trojan)"
echo "===================================="
echo "1) Tambah User Manual"
echo "2) Tambah UDP User"
echo "3) Tambah Trojan User"
echo "4) Tambah Trial User"
echo "5) Hapus User"
echo "6) Daftar User"
echo "7) Remove Script"
echo "8) Torrent Blocker"
echo "9) Restart All Server"
echo "10) Set Telegram Bot"
echo "11) Keluar"
echo "===================================="
read -p "Pilih menu [1-11]: " pilih

case $pilih in
1) create_user ;;
2) create_udp ;;
3) create_trojan ;;
4) create_trial ;;
5) $SYSTEM_DIR/DelUser.sh ;;
6) cat $DB ; read ;;
7) $SYSTEM_DIR/RemoveScript.sh ;;
8) $SYSTEM_DIR/torrent.sh ;;
9)
    systemctl restart ssh xray nginx trojan udp-custom
    echo -e "${GREEN}Semua server direstart!${NC}" ; sleep 2 ;;
10)
    read -p "Token Bot: " BOT_TOKEN
    read -p "Chat ID: " CHAT_ID
    echo "BOT_TOKEN=$BOT_TOKEN" > $TG_CONF
    echo "CHAT_ID=$CHAT_ID" >> $TG_CONF
    echo -e "${GREEN}Telegram Bot disimpan!${NC}" ; sleep 2 ;;
11) exit ;;
*) echo -e "${RED}Pilihan salah!${NC}" ; sleep 1 ;;
esac
done
EOF

chmod +x /usr/local/bin/menu

# ===================== AUTO MENU LOGIN =====================
if ! grep -q "/usr/local/bin/menu" /root/.bashrc; then
    echo "/usr/local/bin/menu" >> /root/.bashrc
fi

clear
banner
echo -e "${green}YHDS VPN PREMIUM installer selesai!${NC}"
echo "Jalankan menu: menu"
