#!/bin/bash
# ================================
# YHDS VPN MAIN MENU - FULL COLOR
# ================================

RED='\e[31m'; GREEN='\e[32m'; BLUE='\e[34m'
YELLOW='\e[33m'; CYAN='\e[36m'; NC='\e[0m'

# -------- STATUS SERVICE ----------
status() {
  for service in udp-custom xray nginx trojan-go; do
    if systemctl is-active --quiet $service; then
      echo -e " ${CYAN}$service${NC} : ${GREEN}ON${NC}"
    else
      echo -e " ${CYAN}$service${NC} : ${RED}OFF${NC}"
    fi
  done
}

# Cek figlet
if ! command -v figlet >/dev/null 2>&1; then
  apt install figlet -y >/dev/null 2>&1
fi

# Cek lolcat
if ! command -v lolcat >/dev/null 2>&1; then
  gem install lolcat >/dev/null 2>&1 || true
fi

# ---------------- MAIN MENU ----------------
while true; do
  clear
  figlet -f slant "YHDS VPN" 2>/dev/null | lolcat 2>/dev/null || echo -e "${CYAN}=== YHDS VPN ===${NC}"

  echo -e "${YELLOW}Status Server:${NC}"
  status
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${YELLOW} 1) Create User (SSH/WS + UDP + Trojan)${NC}"
  echo -e "${YELLOW} 2) Hapus User${NC}"
  echo -e "${YELLOW} 3) Daftar User${NC}"
  echo -e "${YELLOW} 4) Create Trojan (port 443/80)${NC}"
  echo -e "${YELLOW} 5) Create Trial (SSH/UDP/Trojan/Xray)${NC}"
  echo -e "${YELLOW} 6) Toggle ON/OFF Akun${NC}"
  echo -e "${YELLOW} 7) Dashboard Status${NC}"
  echo -e "${YELLOW} 8) Install Bot Telegram Notifikasi${NC}"
  echo -e "${YELLOW} 9) Restart Semua Service${NC}"
  echo -e "${YELLOW}10) Uninstall / Remove Script${NC}"
  echo -e "${YELLOW}11) Keluar${NC}"
  echo -e "${BLUE}========================================${NC}"
  read -p "Pilih menu [1-11]: " opt

  case "$opt" in
    1) /etc/YHDS/system/creatuser.sh; read -p "Enter..." ;;
    2) /etc/YHDS/system/DelUser.sh; read -p "Enter..." ;;
    3) /etc/YHDS/system/Userlist.sh; read -p "Enter..." ;;
    4) /etc/YHDS/system/CreateTrojan.sh; read -p "Enter..." ;;
    5) /etc/YHDS/system/CreateTrial.sh; read -p "Enter..." ;;
    6) /etc/YHDS/system/ToggleUser.sh; read -p "Enter..." ;;
    7) /etc/YHDS/system/DashboardStatus.sh; read -p "Enter..." ;;
    8) /etc/YHDS/system/InstallBot.sh; read -p "Enter..." ;;
    9)
       echo "Restarting services..."
       for s in udp-custom xray nginx trojan-go; do
         systemctl restart $s >/dev/null 2>&1
       done

       if [ -f /etc/YHDS/system/common.sh ]; then
         source /etc/YHDS/system/common.sh
         send_tele "*YHDS VPN Restart*\nSemua service direstart pada $(date '+%Y-%m-%d %H:%M:%S')"
       fi

       echo -e "${GREEN}Selesai restart!${NC}"
       read -p "Enter..."
       ;;
    10)
       read -p "Yakin hapus semua script YHDS? (y/n): " YN
       if [[ "$YN" == "y" ]]; then
         systemctl stop udp-custom >/dev/null 2>&1
         systemctl disable udp-custom >/dev/null 2>&1
         rm -rf /etc/YHDS /root/udp /usr/local/bin/menu
         echo -e "${RED}Semua script dihapus!${NC}"
         exit 0
       fi
       ;;
    11) exit 0 ;;
    *) echo "Pilihan tidak valid"; sleep 1 ;;
  esac
done
