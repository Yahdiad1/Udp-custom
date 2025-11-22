#!/bin/bash
# =========================================
# YHDS VPN UDP-Custom Single Installer
# Tanpa Trojan-Go, menu terbaru otomatis
# Supports Ubuntu/Debian 20/22
# =========================================

set -euo pipefail
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'; NC='\033[0m'

INSTALL_DIR="/root/udp"
MENU_DIR="/etc/YHDS"
LOG_DIR="/root/YHDS-logs"
SYSTEMD_FILE="/etc/systemd/system/udp-custom.service"
GITHUB_RAW="https://raw.githubusercontent.com/Yahdiad1/Udp-custom/main"
ENABLE_IPV6_DISABLE=true

mkdir -p "$INSTALL_DIR" "$MENU_DIR" "$LOG_DIR"

echo -e "${GREEN}Step 1: Update & install dependencies...${NC}"
apt update -y && apt upgrade -y
apt install -y curl wget unzip screen bzip2 gzip figlet lolcat jq

# -------------------------------
# Optional IPv6 disable
# -------------------------------
if [ "$ENABLE_IPV6_DISABLE" = true ]; then
    echo -e "${YELLOW}Disabling IPv6...${NC}"
    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1
    sysctl -w net.ipv6.conf.lo.disable_ipv6=1
    grep -qxF 'net.ipv6.conf.all.disable_ipv6=1' /etc/sysctl.conf || echo 'net.ipv6.conf.all.disable_ipv6=1' >> /etc/sysctl.conf
    grep -qxF 'net.ipv6.conf.default.disable_ipv6=1' /etc/sysctl.conf || echo 'net.ipv6.conf.default.disable_ipv6=1' >> /etc/sysctl.conf
    grep -qxF 'net.ipv6.conf.lo.disable_ipv6=1' /etc/sysctl.conf || echo 'net.ipv6.conf.lo.disable_ipv6=1' >> /etc/sysctl.conf
    sysctl -p
fi

# -------------------------------
# Install Xray
# -------------------------------
echo -e "${GREEN}Installing Xray...${NC}"
bash -c "$(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)" >/root/YHDS-logs/xray-install.log 2>&1 || {
    echo -e "${RED}Xray install failed. Check log${NC}"
    exit 1
}

# -------------------------------
# Download UDP-Custom
# -------------------------------
echo -e "${GREEN}Downloading UDP-Custom binary...${NC}"
wget -q "$GITHUB_RAW/udp-custom-linux-amd64" -O "$INSTALL_DIR/udp-custom" || {
    echo -e "${RED}Failed to download UDP-Custom binary${NC}"
    exit 1
}
chmod +x "$INSTALL_DIR/udp-custom"

# -------------------------------
# Create systemd service
# -------------------------------
echo -e "${GREEN}Creating UDP-Custom service...${NC}"
cat << EOF > "$SYSTEMD_FILE"
[Unit]
Description=YHDS VPN UDP-Custom
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/udp-custom
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

# -------------------------------
# Download & setup NEW menu
# -------------------------------
echo -e "${GREEN}Downloading menu.sh (NEW version)...${NC}"
wget -q "$GITHUB_RAW/menu.sh" -O "$MENU_DIR/menu.sh" || {
    echo -e "${RED}Failed to download menu.sh${NC}"
    exit 1
}
chmod +x "$MENU_DIR/menu.sh"
ln -sf "$MENU_DIR/menu.sh" /usr/local/bin/menu
chmod +x /usr/local/bin/menu
grep -qxF 'menu' /root/.bashrc || echo 'menu' >> /root/.bashrc

# -------------------------------
# Final message
# -------------------------------
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}Use command ${YELLOW}menu${BLUE} to open the VPN management menu.${NC}"
echo -e "${BLUE}Logs stored at: ${LOG_DIR}${NC}"
