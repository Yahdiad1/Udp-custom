#!/bin/bash

# =====================================
# FULL INSTALLER YHDS VPN (UDP + SSH/WS + Xray + Nginx + Trojan)
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
figlet -f slant "YHDS VPN" | lolcat
echo "Installer YHDS VPN - UDP, SSH/WS, Xray, Nginx, Trojan" | lolcat
sleep 3

# Set timezone Sri Lanka GMT+5:30
ln -fs /usr/share/zoneinfo/Asia/Colombo /etc/localtime
echo "Timezone diubah ke GMT+5:30 (Sri Lanka)"

# ===============================
# Install Xray
# ===============================
echo "Installing Xray..."
bash -c "$(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)" >/dev/null 2>&1

# ===============================
# Install Nginx
# ===============================
echo "Installing Nginx..."
apt install nginx -y
systemctl enable nginx
systemctl start nginx

# ===============================
# Install Trojan-go
# ===============================
echo "Installing Trojan..."
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
systemctl start udp-custom
systemctl enable udp-custom

# ===============================
# Download skrip pendukung menu
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
# YHDS VPN Menu

status_server() {
    clear
    figlet -f slant "SERVER STATUS" | lolcat
    echo "=============================================="
    echo "              STATUS LAYANAN"
    echo "=============================================="

    # UDP
    if systemctl is-active --quiet udp-custom; then
        echo -e "UDP Custom        : \e[32mONLINE\e[0m"
    else
        echo -e "UDP Custom        : \e[31mOFFLINE\e[0m"
    fi

    # SSH
    if systemctl is-active --quiet ssh; then
        echo -e "SSH               : \e[32mONLINE\e[0m"
    else
        echo -e "SSH               : \e[31mOFFLINE\e[0m"
    fi

    # NGINX
    if systemctl is-active --quiet nginx; then
        echo -e "Nginx             : \e[32mONLINE\e[0m"
    else
        echo -e "Nginx             : \e[31mOFFLINE\e[0m"
    fi

    # XRAY
    if systemctl is-active --quiet xray; then
        echo -e "Xray              : \e[32mONLINE\e[0m"
    else
        echo -e "Xray              : \e[31mOFFLINE\e[0m"
    fi

    # TROJAN
    if systemctl is-active --quiet trojan; then
        echo -e "Trojan            : \e[32mONLINE\e[0m"
    else
        echo -e "Trojan            : \e[31mOFFLINE\e[0m"
    fi

    echo ""
    echo "=============================================="
    echo "               STATUS AKUN"
    echo "=============================================="

    # Hitung akun SSH
    SSH_COUNT=$(grep -c "/bin/false" /etc/passwd)
    echo "Total Akun SSH/WS       : $SSH_COUNT"

    # Akun UDP
    if [[ -f /etc/YHDS/system/udp-users.txt ]]; then
        UDP_COUNT=$(wc -l < /etc/YHDS/system/udp-users.txt)
    else
        UDP_COUNT=0
    fi
    echo "Total Akun UDP          : $UDP_COUNT"

    # Akun XRAY
    XRAY_COUNT=$(grep -c '"id"' /usr/local/etc/xray/config.json 2>/dev/null)
    echo "Total Akun Xray         : $XRAY_COUNT"

    # Akun TROJAN
    TROJAN_COUNT=$(grep -c '"password"' /usr/local/etc/trojan/config.json 2>/dev/null)
    echo "Total Akun Trojan       : $TROJAN_COUNT"

    echo ""
    echo "Akun SSH/WS Aktif:"
    last | head
    echo ""
    echo "Tekan ENTER untuk kembali..."
    read
}

toggle_accounts() {
    clear
    figlet -f slant "ACCOUNT ON/OFF" | lolcat
    echo "=================================="
    echo "1) Nonaktifkan semua akun SSH/WS"
    echo "2) Aktifkan semua akun SSH/WS"
    echo "3) Nonaktifkan semua akun UDP"
    echo "4) Aktifkan semua akun UDP"
    echo "5) Nonaktifkan semua akun Xray"
    echo "6) Aktifkan semua akun Xray"
    echo "7) Nonaktifkan semua akun Trojan"
    echo "8) Aktifkan semua akun Trojan"
    echo "9) Kembali ke menu utama"
    echo "=================================="
    read -p "Pilih menu [1-9]: " choice

    case $choice in
        1) pkill -u $(awk -F: '/\/bin\/false/{print $1}' /etc/passwd); echo "Semua akun SSH/WS nonaktif"; sleep 2 ;;
        2) echo "Aktifkan semua akun SSH/WS (manual enable jika ada skrip)"; sleep 2 ;;
        3) if [[ -f /etc/YHDS/system/udp-users.txt ]]; then mv /etc/YHDS/system/udp-users.txt /etc/YHDS/system/udp-users.txt.off; fi; echo "Semua akun UDP nonaktif"; sleep 2 ;;
        4) if [[ -f /etc/YHDS/system/udp-users.txt.off ]]; then mv /etc/YHDS/system/udp-users.txt.off /etc/YHDS/system/udp-users.txt; fi; echo "Semua akun UDP aktif"; sleep 2 ;;
        5) echo "Xray akun nonaktif (gunakan skrip Xray manual)"; sleep 2 ;;
        6) echo "Xray akun aktif (gunakan skrip Xray manual)"; sleep 2 ;;
        7) echo "Trojan akun nonaktif (gunakan skrip Trojan manual)"; sleep 2 ;;
        8) echo "Trojan akun aktif (gunakan skrip Trojan manual)"; sleep 2 ;;
        9) return ;;
        *) echo "Pilihan tidak valid"; sleep 2 ;;
    esac
}

while true; do
    clear
    figlet -f slant "YHDS VPN" | lolcat
    echo "==========================================="
    echo "             YHDS VPN MENU"
    echo "==========================================="
    echo "1) Create User UDP"
    echo "2) Create User SSH/WS Manual (non-80/443)"
    echo "3) Create User SSH/WS Trial"
    echo "4) Delete User"
    echo "5) List Users"
    echo "6) Remove Script"
    echo "7) Torrent"
    echo "8) Restart All Server (UDP, Xray, Nginx, Trojan)"
    echo "9) Restart UDP Custom"
    echo "10) Status Server & Akun"
    echo "11) On/Off Semua Akun"
    echo "12) Exit"
    echo "==========================================="
    read -p "Pilih menu [1-12]: " option

    case $option in
        1) /etc/YHDS/system/Adduser.sh udp ;;
        2) /etc/YHDS/system/Adduser.sh ;;
        3) /etc/YHDS/system/Adduser.sh trial ;;
        4) /etc/YHDS/system/DelUser.sh ;;
        5) /etc/YHDS/system/Userlist.sh ;;
        6) /etc/YHDS/system/RemoveScript.sh ;;
        7) /etc/YHDS/system/torrent.sh ;;
        8)
            echo "Restarting semua service..."
            systemctl restart udp-custom xray nginx trojan ssh
            echo "Done!"
            sleep 2
            ;;
        9)
            echo "Restart UDP Custom..."
            systemctl restart udp-custom
            sleep 2
            ;;
        10)
            status_server
            ;;
        11)
            toggle_accounts
            ;;
        12)
            exit
            ;;
        *)
            echo "Pilihan tidak valid!"
            sleep 2
            ;;
    esac

    read -p "Tekan Enter untuk kembali ke menu..."
done
EOM

chmod +x /usr/local/bin/menu

# Jalankan menu otomatis saat login
if ! grep -q "/usr/local/bin/menu" /root/.bashrc; then
    echo "/usr/local/bin/menu" >> /root/.bashrc
fi

# Finish
clear
figlet -f slant "YHDS VPN" | lolcat
echo "YHDS VPN berhasil diinstall!"
echo "UDP, SSH/WS, Xray, Nginx, Trojan siap digunakan"
echo "Menu otomatis muncul setelah close atau login kembali"
echo "Github: https://github.com/Yahdiad1/Udp-custom"
