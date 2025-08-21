#!/bin/bash
# ============================================
# VPS BURGOS - Menu con SSH + SSL (Stunnel)
# ============================================

# ====== COLORES ======
verde="\e[1;32m"
rojo="\e[1;31m"
amarillo="\e[1;33m"
cyan="\e[1;36m"
morado="\e[1;35m"
reset="\e[0m"

# ====== BANNER ======
banner() {
    clear
    echo -e "${cyan}══════════════════════════════════════${reset}"
    echo -e "     ${morado}⚡ BIENVENIDO A VPS BURGOS ⚡${reset}"
    echo -e "${cyan}══════════════════════════════════════${reset}"
}

# ====== INSTALACION DE PAQUETES ======
instalar_dependencias() {
    apt update -y
    apt install -y sudo curl wget unzip socat net-tools
    apt install -y stunnel4
}

# ====== CONFIGURACION STUNNEL ======
configurar_stunnel() {
    cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no

[ssh_444]
accept = 444
connect = 127.0.0.1:22
EOF

    # Crear certificado autofirmado
    openssl req -new -x509 -days 365 -nodes -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem \
        -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=vps-burgos"
    chmod 600 /etc/stunnel/stunnel.pem

    systemctl enable stunnel4
    systemctl restart stunnel4
}

# ====== LISTAR USUARIOS SSH ======
listar_usuarios() {
    clear
    echo -e "${cyan}══════════════════════════════════════${reset}"
    echo -e "       ${verde}👤 LISTA DE USUARIOS SSH ACTIVOS${reset}"
    echo -e "${cyan}══════════════════════════════════════${reset}"

    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd

    echo -e "${cyan}══════════════════════════════════════${reset}"
    read -p "Presiona Enter para volver al menú..."
}

# ====== GESTION DE PUERTOS SSL ======
gestionar_ssl() {
    while true; do
        clear
        echo -e "${cyan}══════════════════════════════════════${reset}"
        echo -e "      ${verde}⚡ GESTIONAR PUERTOS SSL (Stunnel) ⚡${reset}"
        echo -e "${cyan}══════════════════════════════════════${reset}"
        echo -e "${amarillo}1)${reset} Listar puertos SSL activos"
        echo -e "${amarillo}2)${reset} Agregar puerto SSL"
        echo -e "${amarillo}3)${reset} Eliminar puerto SSL"
        echo -e "${rojo}0)${reset} Volver al menú principal"
        echo -e "${cyan}══════════════════════════════════════${reset}"
        read -p "Elige una opción: " opcion_ssl

        case $opcion_ssl in
            1)
                echo -e "${verde}[INFO] Puertos SSL activos:${reset}"
                grep "accept" /etc/stunnel/stunnel.conf | awk '{print $3}'
                read -p "Presiona Enter para continuar..."
                ;;
            2)
                read -p "Ingresa el nuevo puerto SSL: " nuevo_puerto
                if grep -q "accept = $nuevo_puerto" /etc/stunnel/stunnel.conf; then
                    echo -e "${rojo}[ERROR] El puerto $nuevo_puerto ya existe.${reset}"
                else
                    echo -e "\n[ssh_$nuevo_puerto]" >> /etc/stunnel/stunnel.conf
                    echo "accept = $nuevo_puerto" >> /etc/stunnel/stunnel.conf
                    echo "connect = 127.0.0.1:22" >> /etc/stunnel/stunnel.conf
                    systemctl restart stunnel4
                    echo -e "${verde}[OK] Puerto $nuevo_puerto agregado y stunnel reiniciado.${reset}"
                fi
                read -p "Presiona Enter para continuar..."
                ;;
            3)
                read -p "Ingresa el puerto SSL a eliminar: " puerto_del
                if grep -q "accept = $puerto_del" /etc/stunnel/stunnel.conf; then
                    sed -i "/\[ssh_$puerto_del\]/,/connect = 127.0.0.1:22/d" /etc/stunnel/stunnel.conf
                    systemctl restart stunnel4
                    echo -e "${verde}[OK] Puerto $puerto_del eliminado.${reset}"
                else
                    echo -e "${rojo}[ERROR] El puerto $puerto_del no está configurado.${reset}"
                fi
                read -p "Presiona Enter para continuar..."
                ;;
            0) break ;;
            *) echo -e "${rojo}[ERROR] Opción inválida.${reset}" ;;
        esac
    done
}

# ====== MENU PRINCIPAL ======
menu_principal() {
    while true; do
        banner
        echo -e "${amarillo}1)${reset} Lista de usuarios SSH"
        echo -e "${amarillo}2)${reset} Gestionar puertos SSL (Stunnel)"
        echo -e "${rojo}0)${reset} Salir"
        echo -e "${cyan}══════════════════════════════════════${reset}"
        read -p "Elige una opción: " opcion

        case $opcion in
            1) listar_usuarios ;;
            2) gestionar_ssl ;;
            0) exit 0 ;;
            *) echo -e "${rojo}[ERROR] Opción inválida.${reset}" ;;
        esac
    done
}

# ====== EJECUCION ======
instalar_dependencias
configurar_stunnel
menu_principal
