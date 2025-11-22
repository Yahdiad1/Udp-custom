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
# YHDS VPN UDP‑Custom

Installer VPN UDP‑Custom terbaru dengan **Xray WS/VLESS** dan **UDP Custom 1‑65535**, dilengkapi menu baru dan tanpa Trojan‑Go.

---

## Fitur
- Install Xray WS / VLESS  
- Install UDP Custom range 1‑65535  
- Menu manajemen lengkap (melalui `menu.sh`)  
- Systemd service untuk UDP‑Custom  
- IPv6 **opsional** di‑disable untuk stabilitas UDP  

---

## Sistem Operasi yang Didukung
- Debian 10 / 11 / 12  
- Ubuntu 20.04 / 22.04  

---

## Cara Install (hanya 1 wget)
Jalankan perintah berikut di VPS (sebagai root):

```bash
cd /root && \
wget -O install.sh "https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main/install.sh" && \
chmod +x install.sh && \
bash install.sh
