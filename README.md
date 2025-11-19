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
cd /root && \
wget -O install.sh https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main/install.sh && \
wget -O menu.sh    https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main/menu.sh && \
chmod +x install.sh menu.sh && \
bash install.sh
