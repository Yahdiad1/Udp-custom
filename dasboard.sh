cat << 'EOM' > /usr/local/bin/menu
#!/bin/bash
# Menu utama YHDS VPN dengan Restart All Server (UDP, Xray, Nginx, Trojan)

while true; do
    clear
    # Banner besar berwarna
    figlet -f slant "YHDS VPN" | lolcat
    echo "=================================="
    echo "          Menu Utama YHDS VPN"
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
