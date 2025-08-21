#!/bin/bash
# ============================================
#  VPS BURGOS - INSTALADOR Y MENU
# ============================================

# --- Colores ---
verde="\e[1;32m"
rojo="\e[1;31m"
amarillo="\e[1;33m"
azul="\e[1;34m"
morado="\e[1;35m"
cyan="\e[1;36m"
reset="\e[0m"

# --- Actualizar sistema ---
echo -e "${amarillo}Actualizando sistema...${reset}"
apt-get update -y && apt-get upgrade -y

# --- Instalar dependencias ---
echo -e "${amarillo}Instalando dependencias...${reset}"
apt-get install -y sudo curl wget unzip stunnel4 net-tools openssh-server

# --- Configurar Stunnel ---
mkdir -p /etc/stunnel

cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no

[ssh-443]
accept = 443
connect = 22
EOF

# Crear certificado autofirmado
openssl req -new -x509 -days 365 -nodes -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem \
-subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com"
chmod 600 /etc/stunnel/stunnel.pem

# Habilitar stunnel
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
systemctl enable stunnel4
systemctl restart stunnel4

# --- Funciones del menú ---
crear_usuario() {
    read -p "Usuario: " user
    read -p "Contraseña: " pass
    read -p "Días de validez: " dias
    exp=$(date -d "+$dias days" +"%Y-%m-%d")
    useradd -e $exp -M -s /bin/false $user
    echo "$user:$pass" | chpasswd
    echo -e "${verde}Usuario $user creado, expira el $exp${reset}"
}

eliminar_usuario() {
    read -p "Usuario a eliminar: " user
    userdel -r $user
    echo -e "${rojo}Usuario $user eliminado${reset}"
}

ver_usuarios() {
    echo -e "${cyan}Lista de usuarios activos:${reset}"
    for user in $(awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd); do
        exp=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')
        echo -e "${verde}$user${reset} - expira: $exp"
    done
}

renovar_usuario() {
    read -p "Usuario: " user
    read -p "Días extra: " dias
    chage -E $(date -d "+$dias days" +"%Y-%m-%d") $user
    echo -e "${verde}Usuario $user renovado por $dias días${reset}"
}

gestionar_ssl() {
    while true; do
        clear
        echo -e "${morado}══════════════════════════════${reset}"
        echo -e "${morado}   GESTIONAR PUERTOS SSL${reset}"
        echo -e "${morado}══════════════════════════════${reset}"
        echo "1) Ver puertos SSL activos"
        echo "2) Agregar puerto SSL"
        echo "3) Eliminar puerto SSL"
        echo "0) Volver"
        read -p "Opción: " opc

        case $opc in
            1)
                grep "accept" /etc/stunnel/stunnel.conf
                read -p "Enter para continuar..."
                ;;
            2)
                read -p "Puerto nuevo: " port
                echo "[ssh-$port]" >> /etc/stunnel/stunnel.conf
                echo "accept = $port" >> /etc/stunnel/stunnel.conf
                echo "connect = 22" >> /etc/stunnel/stunnel.conf
                systemctl restart stunnel4
                echo -e "${verde}Puerto $port agregado y stunnel reiniciado${reset}"
                read -p "Enter para continuar..."
                ;;
            3)
                read -p "Puerto a eliminar: " port
                sed -i "/\[ssh-$port\]/,/connect = 22/d" /etc/stunnel/stunnel.conf
                systemctl restart stunnel4
                echo -e "${rojo}Puerto $port eliminado y stunnel reiniciado${reset}"
                read -p "Enter para continuar..."
                ;;
            0) break ;;
        esac
    done
}

# --- Menú principal ---
menu() {
    while true; do
        clear
        echo -e "${azul}══════════════════════════════${reset}"
        echo -e "${azul}     VPS BURGOS - MENU${reset}"
        echo -e "${azul}══════════════════════════════${reset}"
        echo "1) Crear usuario"
        echo "2) Eliminar usuario"
        echo "3) Ver usuarios activos"
        echo "4) Renovar usuario"
        echo "5) Gestionar puertos SSL"
        echo "0) Salir"
        read -p "Opción: " opcion
        case $opcion in
            1) crear_usuario ;;
            2) eliminar_usuario ;;
            3) ver_usuarios ;;
            4) renovar_usuario ;;
            5) gestionar_ssl ;;
            0) exit ;;
            *) echo "Opción inválida" ;;
        esac
        read -p "Enter para continuar..."
    done
}

menu