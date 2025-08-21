#!/bin/bash
# ================================================
#  VPS Manager - Menu Burgos (con puertos SSL extra)
# ================================================

# Colores
rojo="\e[1;31m"
verde="\e[1;32m"
amarillo="\e[1;33m"
azul="\e[1;34m"
morado="\e[1;35m"
cyan="\e[1;36m"
blanco="\e[1;37m"
reset="\e[0m"

# Mensaje de bienvenida
clear
echo -e "${morado}============================================${reset}"
echo -e "        ${cyan}Bienvenido a VPS Burgos 🚀${reset}"
echo -e "${morado}============================================${reset}"

# Instalación inicial
function instalar_requisitos() {
    apt-get update -y
    apt-get install -y wget curl openssl ufw stunnel4

    # Configuración firewall básica
    ufw allow 22/tcp
    ufw allow 443/tcp
    ufw allow 444/tcp
    ufw --force enable

    # Generar certificado para stunnel
    openssl req -new -x509 -days 365 -nodes \
        -out /etc/stunnel/stunnel.pem \
        -keyout /etc/stunnel/stunnel.pem \
        -subj "/C=US/ST=Burgos/L=VPS/O=BurgosVPN/CN=burgosvpn.local"
    chmod 600 /etc/stunnel/stunnel.pem

cat > /etc/stunnel/stunnel.conf <<-EOF
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no

[ssh-443]
accept = 443
connect = 22

[ssh-444]
accept = 444
connect = 22
EOF

    systemctl enable stunnel4
    systemctl restart stunnel4
    echo -e "${verde}Instalación inicial completa.${reset}"
}

# Funciones principales
function listar_usuarios() {
    echo -e "${amarillo}==== Lista de usuarios SSH activos ====${reset}"
    while IFS=: read -r user _ uid _ _ expire _; do
        if [[ $uid -ge 1000 && $user != "nobody" ]]; then
            expdate=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')
            echo -e "${verde}Usuario:${reset} $user  ${morado}| Expira:${reset} $expdate"
        fi
    done < /etc/passwd
    echo -e "${amarillo}======================================${reset}"
}

function crear_usuario() {
    read -p "Usuario: " user
    read -p "Contraseña: " pass
    read -p "Días de validez: " days
    expdate=$(date -d "$days days" +"%Y-%m-%d")
    useradd -e $expdate -M -s /bin/false $user
    echo "$user:$pass" | chpasswd
    echo -e "${verde}Usuario creado:${reset} $user  ${morado}| Expira:${reset} $expdate"
}

function eliminar_usuario() {
    read -p "Usuario a eliminar: " user
    userdel -r $user
    echo -e "${rojo}Usuario eliminado:${reset} $user"
}

function renovar_usuario() {
    read -p "Usuario a renovar: " user
    read -p "Días adicionales: " days
    current_exp=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')
    if [[ $current_exp == "never" ]]; then
        new_exp=$(date -d "$days days" +"%Y-%m-%d")
    else
        new_exp=$(date -d "$current_exp + $days days" +"%Y-%m-%d")
    fi
    chage -E $new_exp $user
    echo -e "${verde}Usuario renovado:${reset} $user  ${morado}| Nuevo vencimiento:${reset} $new_exp"
}

function eliminar_caducados() {
    echo -e "${rojo}Eliminando usuarios caducados...${reset}"
    today=$(date +%s)
    while IFS=: read -r user _ uid _ _ expire _; do
        if [[ $uid -ge 1000 && $user != "nobody" ]]; then
            expdate=$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')
            if [[ $expdate != "never" ]]; then
                exp_sec=$(date -d "$expdate" +%s)
                if [[ $exp_sec -lt $today ]]; then
                    userdel -r $user
                    echo -e "${rojo}Usuario caducado eliminado:${reset} $user"
                fi
            fi
        fi
    done < /etc/passwd
}

function configurar_puertos() {
    read -p "Puerto adicional SSH a habilitar: " port
    echo "Port $port" >> /etc/ssh/sshd_config
    ufw allow $port/tcp
    systemctl restart ssh
    echo -e "${verde}Puerto $port agregado y SSH reiniciado${reset}"
}

function agregar_ssl_puerto() {
    read -p "Puerto adicional SSL para stunnel: " port
    echo -e "[ssh-$port]\naccept = $port\nconnect = 22" >> /etc/stunnel/stunnel.conf
    ufw allow $port/tcp
    systemctl restart stunnel4
    echo -e "${verde}Puerto SSL $port agregado a stunnel y habilitado en firewall${reset}"
}

# Menu
while true; do
    echo -e ""
    echo -e "${morado}=========== MENU BURGOS ===========${reset}"
    echo -e "${verde}1)${reset} Listar usuarios SSH"
    echo -e "${verde}2)${reset} Crear nuevo usuario"
    echo -e "${verde}3)${reset} Eliminar usuario"
    echo -e "${verde}4)${reset} Renovar usuario"
    echo -e "${verde}5)${reset} Eliminar usuarios caducados"
    echo -e "${verde}6)${reset} Configurar puertos SSH"
    echo -e "${verde}7)${reset} Instalar/Reinstalar Stunnel"
    echo -e "${verde}8)${reset} Agregar puerto SSL adicional"
    echo -e "${rojo}0)${reset} Salir"
    echo -e "${morado}==================================${reset}"
    read -p "Selecciona una opción: " opt
    case $opt in
        1) listar_usuarios ;;
        2) crear_usuario ;;
        3) eliminar_usuario ;;
        4) renovar_usuario ;;
        5) eliminar_caducados ;;
        6) configurar_puertos ;;
        7) instalar_requisitos ;;
        8) agregar_ssl_puerto ;;
        0) exit ;;
        *) echo -e "${rojo}Opción inválida${reset}" ;;
    esac
done