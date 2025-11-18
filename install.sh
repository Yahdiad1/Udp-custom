#!/bin/bash

# =====================================
# FULL INSTALLER YHDS VPN (UDP + SSH/WS + Xray + Nginx + Trojan-go + Telegram)
# =====================================

# Update & install tools
apt update -y
apt upgrade -y
apt install lolcat figlet neofetch screenfetch unzip curl wget column -y

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
figlet -f slant "YHDS VPN" | lolcat
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
# Install Trojan-go dengan service
# ===============================
echo "Install Trojan-go..."
wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.4/trojan-go-linux-amd64.zip -O /tmp/trojan-go.zip
unzip /tmp/trojan-go.zip -d /usr/local/bin/
chmod +x /usr/local/bin/trojan-go

mkdir -p /etc/trojan-go
cat <<EOF > /etc/trojan-go/config.json
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
EOF

cat <<EOF > /etc/systemd/system/trojan-go.service
[Unit]
Description=Trojan-go Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/trojan-go -config /etc/trojan-go/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable trojan-go
systemctl start trojan-go

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

systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

# ===============================
# Download skrip tambahan menu
# ===============================
mkdir -p /etc/YHDS
cd /etc/YHDS
wget "$GITHUB_RAW/system.zip"
unzip system.zip
cd system
mv menu /usr/local/bin
chmod +x menu Adduser.sh DelUser.sh Userlist.sh RemoveScript.sh torrent.sh
cd /etc/YHDS
rm system.zip

# ===============================
# Buat menu looping otomatis
# ===============================
cat << 'EOM' > /usr/local/bin/menu
#!/bin/bash

while true; do
    clear
    figlet -f slant "YHDS VPN" | lolcat
    echo "=================================="
    echo "       MENU UTAMA YHDS VPN"
    echo "=================================="
    echo "1) Tambah User SSH/WS/UDP"
    echo "2) Hapus User"
    echo "3) Daftar User"
    echo "4) Remove Script"
    echo "5) Torrent"
    echo "6) Restart All Server (UDP, Xray, Nginx, Trojan-go)"
    echo "7) Toggle On/Off Akun UDP/SSH/WS"
    echo "8) Dashboard Status Server & Akun"
    echo "9) Install & Setup Telegram Bot"
    echo "10) Keluar"
    echo "=================================="
    read -p "Pilih menu [1-10]: " option

    case $option in
        1) /etc/YHDS/system/Adduser.sh ;;
        2) /etc/YHDS/system/DelUser.sh ;;
        3) /etc/YHDS/system/Userlist.sh ;;
        4) /etc/YHDS/system/RemoveScript.sh ;;
        5) /etc/YHDS/system/torrent.sh ;;
        6)
            echo "Restart semua service..."
            for srv in udp-custom xray nginx trojan-go; do
                if systemctl list-units --full -all | grep -q "^$srv"; then
                    systemctl restart $srv
                fi
            done
            echo "Semua service sudah direstart!"
            sleep 3
            ;;
        7)
            echo "Toggle ON/OFF akun"
            if [ -f /etc/YHDS/system/udp-users.txt ]; then
                nano /etc/YHDS/system/udp-users.txt
            else
                echo "Belum ada akun UDP/SSH/WS"
                sleep 2
            fi
            ;;
        8)
            clear
            echo "=================================="
            echo "       DASHBOARD SERVER"
            echo "=================================="
            echo "Status Service:"
            for srv in udp-custom xray nginx trojan-go; do
                systemctl status $srv --no-pager
            done
            echo ""
            echo "AKUN UDP/SSH/WS:"
            if [ -f /etc/YHDS/system/udp-users.txt ]; then
                while IFS="|" read -r username status expire; do
                    if [[ "$status" == "ON" ]]; then
                        echo -e "\e[34m$username | $status | $expire\e[0m"
                    else
                        echo -e "\e[31m$username | $status | $expire\e[0m"
                    fi
                done < /etc/YHDS/system/udp-users.txt
            else
                echo "Belum ada akun dibuat"
            fi
            read -p "Tekan Enter untuk kembali..."
            ;;
        9)
            echo "Setup Telegram Bot..."
            read -p "Masukkan Bot Token: " BOT_TOKEN
            read -p "Masukkan Chat ID: " CHAT_ID
            mkdir -p /etc/YHDS
            echo "BOT_TOKEN=$BOT_TOKEN" > /etc/YHDS/telegram.conf
            echo "CHAT_ID=$CHAT_ID" >> /etc/YHDS/telegram.conf
            echo "Telegram Bot berhasil disimpan!"
            sleep 2
            ;;
        10) echo "Keluar dari menu"; exit ;;
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

clear
echo "=========================================="
echo "YHDS VPN berhasil diinstall!"
echo "UDP, SSH/WS, Xray, Nginx, Trojan-go siap digunakan"
echo "IPv6 dinonaktifkan, UDP lebih stabil"
echo "Menu utama: menu"
echo "Menu akan otomatis muncul setelah close atau login kembali"
echo "Dashboard menampilkan ON biru / OFF merah"
echo "Github: https://github.com/Yahdiad1/Udp-custom"
echo "=========================================="
