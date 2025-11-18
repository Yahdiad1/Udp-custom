#!/bin/bash

# =====================================
# FULL INSTALLER YHDS VPN (UDP + Xray + Nginx + Trojan)
# =====================================

# Update dan install tools
apt update -y
apt upgrade -y
apt install lolcat figlet neofetch screenfetch unzip curl wget -y

# Disable IPv6 supaya UDP lebih stabil
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

# Banner YHDS VPN
clear
echo -e "          ░█▀▀▀█ ░█▀▀▀█ ░█─── ─█▀▀█ ░█▀▀█   ░█─░█ ░█▀▀▄ ░█▀▀█ " | lolcat
echo -e "          ─▀▀▀▄▄ ░▀▀▀▄▄ ░█─── ░█▄▄█ ░█▀▀▄   ░█─░█ ░█─░█ ░█▄▄█ " | lolcat
echo -e "          ░█▄▄▄█ ░█▄▄▄█ ░█▄▄█ ░█─░█ ░█▄▄█   ░█▄▄▀ ░█▄▄▀ ░█─── " | lolcat
echo ""
echo "        YHDS VPN Installer"
sleep 3

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
# Install Trojan
# ===============================
echo "Install Trojan..."
# Gunakan installer Trojan resmi (misal dari GitHub)
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
# Buat menu looping otomatis
# ===============================
cat << 'EOM' > /usr/local/bin/menu
#!/bin/bash
# Menu utama YHDS VPN dengan Restart All Server (UDP, Xray, Nginx, Trojan)

while true; do
    clear
    echo "=================================="
    echo "       YHDS VPN MENU"
    echo "=================================="
    echo "1) Tambah User"
    echo "2) Hapus User"
    echo "3) Daftar User"
    echo "4) Remove Script"
    echo "5) Torrent"
    echo "6) Restart All Server (UDP, Xray, Nginx, Trojan)"
    echo "7) Keluar"
    echo "=================================="
    read -p "Pilih menu [1-7]: " option

    case $option in
        1) /etc/YHDS/system/Adduser.sh ;;
        2) /etc/YHDS/system/DelUser.sh ;;
        3) /etc/YHDS/system/Userlist.sh ;;
        4) /etc/YHDS/system/RemoveScript.sh ;;
        5) /etc/YHDS/system/torrent.sh ;;
        6)
            echo "Restart semua service..."
            systemctl restart udp-custom xray nginx trojan
            echo "Semua service sudah direstart!"
            sleep 3
            ;;
        7) echo "Keluar dari menu"; exit ;;
        *) echo "Pilihan salah"; sleep 2 ;;
    esac

    read -p "Tekan Enter untuk kembali ke menu..."
done
EOM

chmod +x /usr/local/bin/menu

# ===============================
# Jalankan menu otomatis saat login
# ===============================
if ! grep -q "/usr/local/bin/menu" /root/.bashrc; then
    echo "/usr/local/bin/menu" >> /root/.bashrc
fi

# ===============================
# Start dan enable service UDP Custom
# ===============================
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
