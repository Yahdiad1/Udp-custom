# YHDS VPN Installer

**Full Installer YHDS VPN** – UDP Custom, Xray, Nginx, Trojan-go, dan Bot Telegram Notifikasi

---

## Fitur Utama
- UDP Custom Manager
- SSH & WebSocket (WS) Account Management
- Trojan-go & Xray Support
- Nginx Web Server
- On/Off Status Server di Dashboard
- Menu interaktif dengan status ON/OFF semua service
- Bot Telegram Notifikasi (opsional)
- Nonaktifkan IPv6 supaya UDP lebih stabil
- Trial account & manual account creation support
- Restart All Server dari menu

---

## Cara Install

1. Download script:

```bash
sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl unzip && wget https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main/install.sh -O install.sh
chmod +x install.sh
bash install.sh
