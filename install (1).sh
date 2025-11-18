#!/bin/bash

# =====================================
# FULL INSTALLER YHDS VPN (UDP + Xray + Nginx + Trojan + Bot Telegram)
# =====================================

# Update & install tools
apt update -y
apt upgrade -y
apt install lolcat figlet neofetch screenfetch unzip curl wget jq -y

# Disable IPv6 supaya UDP stabil
echo "Menonaktifkan IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

# Hapus folder lama dan buat folder baru
rm -rf /root/udp
mkdir -p /root/udp

# Banner YHDS VPN besar dan berwarna
clear
figlet -f slant "YHDS VPN" | lolcat
echo ""
echo "        Installer YHDS VPN"
sleep 2

# Set timezone Sri Lanka GMT+5:30
ln -fs /usr/share/zoneinfo/Asia/Colombo /etc/localtime
echo "Timezone diubah ke GMT+5:30 (Sri Lanka)"

# ===============================
# Install Xray
# ===============================
echo "Install Xray..."
bash -c "$(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)" >/dev/null 2>&1

# ===============================
# Install Nginx
# ===============================
echo "Install Nginx..."
apt install nginx -y
systemctl enable nginx
systemctl start nginx

# ===============================
# Install Trojan-go
# ===============================
echo "Install Trojan-go..."
bash -c "$(curl -sL https://raw.githubusercontent.com/p4gefau1t/trojan-install/master/trojan.sh)" >/dev/null 2>&1

# ===============================
# Download UDP Custom dari GitHub
# ===============================
GITHUB_RAW="https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main"

echo "Download UDP Custom binary..."
wget "$GITHUB_RAW/udp-custom-linux-amd64" -O /root/udp/udp-custom
chmod +x /root/udp/udp-custom

echo "Download default config..."
wget "$GITHUB_RAW/config.json" -O /root/udp/config.json
chmod 644 /root/udp/config.json

# ===============================
# Buat systemd service UDP Custom
# ===============================
if [ -z "$1" ]; then
cat <<EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=YHDS VPN UDP Custom

[Service]
User=root
Type=simple
ExecStart=/root/udp/udp-custom server
WorkingDirectory=/root/udp/
Restart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF
else
cat <<EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=YHDS VPN UDP Custom

[Service]
User=root
Type=simple
ExecStart=/root/udp/udp-custom server -exclude $1
WorkingDirectory=/root/udp/
Restart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF
fi

# ===============================
# Download skrip tambahan menu
# ===============================
mkdir -p /etc/YHDS
cd /etc/YHDS
wget "$GITHUB_RAW/system.zip"
unzip system.zip
cd system
mv menu /usr/local/bin
chmod +x menu ChangeUser.sh Adduser.sh DelUser.sh Userlist.sh RemoveScript.sh torrent.sh
cd /etc/YHDS
rm system.zip

# ===============================
# Menu utama YHDS VPN full dengan dashboard
# ===============================
cat << 'EOM' > /usr/local/bin/menu
#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
YELLOW='\e[33m'
NC='\e[0m'

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
    # Banner besar YHDS VPN
    figlet -f slant "YHDS VPN" | lolcat
    echo ""
    echo -e "${YELLOW}Status Server:${NC}"
    status
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${YELLOW}1) Tambah User SSH/WS${NC}"
    echo -e "${YELLOW}2) Hapus User${NC}"
    echo -e "${YELLOW}3) Daftar User${NC}"
    echo -e "${YELLOW}4) Remove Script${NC}"
    echo -e "${YELLOW}5) Torrent${NC}"
    echo -e "${YELLOW}6) Restart Semua Server (UDP/Xray/Nginx/Trojan)${NC}"
    echo -e "${YELLOW}7) Toggle On/Off Akun${NC}"
    echo -e "${YELLOW}8) Install Bot Telegram Notifikasi${NC}"
    echo -e "${YELLOW}9) Keluar${NC}"
    echo -e "${BLUE}========================================${NC}"
    read -p "Pilih menu [1-9]: " option

    case $option in
        1) /etc/YHDS/system/Adduser.sh ;;
        2) /etc/YHDS/system/DelUser.sh ;;
        3) /etc/YHDS/system/Userlist.sh ;;
        4) /etc/YHDS/system/RemoveScript.sh ;;
        5) /etc/YHDS/system/torrent.sh ;;
        6)
            echo "Restart semua service..."
            systemctl restart udp-custom xray nginx trojan-go
            echo "Semua service sudah direstart!"
            sleep 3
            ;;
        7) /etc/YHDS/system/ChangeUser.sh ;;
        8)
            read -p "Masukkan TOKEN BOT: " BOT_TOKEN
            read -p "Masukkan CHAT ID: " CHAT_ID
            echo "Bot Telegram akan mengirim notifikasi..."
            echo "TOKEN=$BOT_TOKEN" >> /etc/YHDS/telegram.env
            echo "CHAT_ID=$CHAT_ID" >> /etc/YHDS/telegram.env
            echo "Selesai! Notifikasi aktif."
            sleep 2
            ;;
        9) echo "Keluar dari menu"; exit ;;
        *) echo "Pilihan salah"; sleep 2 ;;
    esac

    read -p "Tekan Enter untuk kembali ke menu..."
done
EOM

chmod +x /usr/local/bin/menu

# Jalankan menu otomatis saat login
if ! grep -q "/usr/local/bin/menu" /root/.bashrc; then
    echo "/usr/local/bin/menu" >> /root/.bashrc
fi

# Start dan enable service UDP Custom
systemctl daemon-reload
systemctl start udp-custom
systemctl enable udp-custom

clear
echo "=========================================="
echo "YHDS VPN berhasil diinstall!"
echo "UDP, Xray, Nginx, Trojan siap digunakan"
echo "IPv6 dinonaktifkan, UDP lebih stabil"
echo "Menu utama: menu"
echo "Menu akan otomatis muncul setelah close atau login kembali"
echo "Github: https://github.com/Yahdiad1/Udp-custom"
echo "=========================================="
