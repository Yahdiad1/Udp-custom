#!/bin/bash

================================================================

YHDS VPN - FULL INSTALLER

UDP Custom + Xray + Nginx + Trojan + SSH WS + Menu Lengkap

Auto Disable IPv6, Auto Fix Services, Auto Menu After Close

Source UDP: GitHub/Yahdiad1/Udp-custom

================================================================

set -euo pipefail export DEBIAN_FRONTEND=noninteractive

=============== DISABLE IPV6 ==================

cat <<EOF > /etc/sysctl.d/99-disable-ipv6.conf net.ipv6.conf.all.disable_ipv6 = 1 net.ipv6.conf.default.disable_ipv6 = 1 net.ipv6.conf.lo.disable_ipv6 = 1 EOF sysctl --system >/dev/null 2>&1

=============== UPDATE SYSTEM ==================

apt update -y && apt upgrade -y apt install -y wget curl zip unzip lolcat figlet screenfetch neofetch socat cron jq

=============== DIRECTORIES ==================

rm -rf /root/udp mkdir -p /root/udp mkdir -p /etc/yhds mkdir -p /usr/local/yhds

=============== BANNER ==================

clear figlet "YHDS VPN" | lolcat echo "Installer Full Loaded..." | lolcat sleep 2

=============== SET TIMEZONE ==================

ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

=============== INSTALL UDP CUSTOM ==================

echo "Downloading UDP-Custom..." | lolcat wget -q "https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main/udp-custom-linux-amd64" -O /root/udp/udp-custom chmod +x /root/udp/udp-custom

wget -q "https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main/config.json" -O /root/udp/config.json chmod 644 /root/udp/config.json

cat <<EOF > /etc/systemd/system/udp-custom.service [Unit] Description=YHDS UDP Custom After=network.target

[Service] User=root ExecStart=/root/udp/udp-custom server WorkingDirectory=/root/udp/ Restart=always RestartSec=2s

[Install] WantedBy=multi-user.target EOF

systemctl daemon-reload systemctl enable udp-custom systemctl restart udp-custom

=============== INSTALL XRAY ==================

echo "Installing Xray..." | lolcat bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)

=============== NGINX ==================

apt install -y nginx systemctl enable nginx systemctl restart nginx

=============== TROJAN-GO ==================

wget -qO- https://api.github.com/repos/p4gefau1t/trojan-go/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f4 | wget -qi - unzip -o trojan-go*.zip -d /usr/local/trojan-go >/dev/null 2>&1 chmod +x /usr/local/trojan-go/trojan-go

=============== SSH + WEBSOCKET ==================

apt install -y dropbear

cat <<EOF >/etc/default/dropbear NO_START=0 DROPBEAR_PORT=109 DROPBEAR_EXTRA_ARGS="-p 143" DROPBEAR_BANNER="/etc/yhds/banner.txt" EOF

systemctl restart dropbear

Websocket

cat <<EOF > /usr/local/bin/ws-ssh #!/usr/bin/env bash while true; do socat TCP-LISTEN:80,reuseaddr,fork TCP:127.0.0.1:109 done EOF chmod +x /usr/local/bin/ws-ssh

cat <<EOF > /etc/systemd/system/ws-ssh.service [Unit] Description=SSH Websocket After=network.target

[Service] ExecStart=/usr/local/bin/ws-ssh Restart=always RestartSec=1

[Install] WantedBy=multi-user.target EOF

systemctl daemon-reload systemctl enable ws-ssh systemctl restart ws-ssh

====================== MENU SYSTEM =========================

mkdir -p /usr/local/yhds/menu

cat <<'EOF' > /usr/local/bin/yhds-menu #!/bin/bash while true; do clear figlet "YHDS VPN" | lolcat echo "1) Create SSH/WS" echo "2) Create Trojan" echo "3) Trial SSH/WS" echo "4) User List" echo "5) Delete User" echo "6) Restart All Server" echo "7) Exit" echo -n "Select: " read opt case $opt in

1. bash /usr/local/yhds/menu/create-ssh ;;


2. bash /usr/local/yhds/menu/create-trojan ;;


3. bash /usr/local/yhds/menu/trial-ssh ;;


4. bash /usr/local/yhds/menu/user-list ;;


5. bash /usr/local/yhds/menu/delete-user ;;


6. systemctl restart udp-custom dropbear ws-ssh nginx xray; echo "All restarted!"; sleep 2;;


7. exit;; esac done EOF chmod +x /usr/local/bin/yhds-menu



==== CREATE SSH ====

cat <<'EOF' > /usr/local/yhds/menu/create-ssh #!/bin/bash clear echo -n "Username: " read u echo -n "Password: " read p echo -n "Expire (days): " read e useradd -e date -d "$e days" +%Y-%m-%d -s /bin/false -M $u echo "$u:$p" | chpasswd echo "SSH Account Created" echo "---------------------------" echo "Host : $(curl -s ifconfig.me)" echo "User : $u" echo "Pass : $p" echo "Port : 22,109,443 WS" echo "Payload WS: GET / HTTP/1.1[crlf]Host: $(curl -s ifconfig.me)[crlf]Upgrade: websocket[crlf][crlf]" EOF chmod +x /usr/local/yhds/menu/create-ssh

==== TRIAL SSH ====

cat <<'EOF' > /usr/local/yhds/menu/trial-ssh #!/bin/bash u=trial-openssl rand -hex 2 p=123 e=1 useradd -e date -d "$e days" +%Y-%m-%d -s /bin/false -M $u echo "$u:$p" | chpasswd clear echo "Trial SSH Created" echo "User : $u" echo "Pass : $p" echo "Expire: 1 day" echo "Payload: GET / HTTP/1.1[crlf]Host: $(curl -s ifconfig.me)[crlf]Upgrade: websocket[crlf][crlf]" EOF chmod +x /usr/local/yhds/menu/trial-ssh

==== USER LIST ====

cat <<'EOF' > /usr/local/yhds/menu/user-list #!/bin/bash cut -d: -f1 /etc/passwd | grep -v nologin echo "Press enter..." read EOF chmod +x /usr/local/yhds/menu/user-list

==== DELETE USER ====

cat <<'EOF' > /usr/local/yhds/menu/delete-user #!/bin/bash echo -n "User to delete: " read u deluser --remove-home $u echo "User deleted." sleep 1 EOF chmod +x /usr/local/yhds/menu/delete-user

=========== MAKE MENU APPEAR AFTER LOGIN ===========

echo "yhds-menu" >> ~/.bashrc

clear figlet "DONE" | lolcat echo "Install Selesai — YHDS VPN Aktif" | lolcat echo "Ketik: yhds-menu"
