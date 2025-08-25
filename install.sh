#!/bin/bash

# ==============================
#   VPS BURGOS - MANAGER SSH
#   Script de gestión de usuarios
# ==============================

# Detectar IP y puertos
IP=$(hostname -I | awk '{print $1}')
SSH_PORT=$(ss -tlnp 2>/dev/null | grep -m1 sshd | awk '{print $4}' | sed 's/.*://')
SSL_PORT=$(ss -tlnp 2>/dev/null | grep stunnel | awk '{print $4}' | sed 's/.*://')

# === Colores degradado púrpura (RocketTunnel Style) ===
c1="\e[38;5;54m"     # Púrpura oscuro
c2="\e[38;5;93m"     # Violeta intenso
c3="\e[38;5;177m"    # Morado pastel
c4="\e[38;5;183m"    # Lila suave
c5="\e[38;5;141m"    # Morado brillante
c6="\e[38;5;219m"    # Lila neón
danger="\e[38;5;196m" # Rojo fuerte
reset="\e[0m"
bold="\e[1m"

# ==============================
# Banner de bienvenida
# ==============================
banner() {
    clear
    echo -e "${c6}============================${reset}"
    echo -e " ${c6}🔒 Bienvenido a VPS Burgos 💜${reset}"
    echo -e " ${c3}------ Tu conexión segura ------${reset}"
    echo -e "${c6}============================${reset}\n"

    echo -e "📱 ${c3}WhatsApp:${reset} ${c2}9851169633${reset}"
    echo -e "📬 ${c3}Telegram:${reset} ${c2}@Escanor_Sama18${reset}\n"

    echo -e "⚠️  ${danger}Acceso autorizado únicamente.${reset}"
    echo -e "🔴 ${danger}Todo acceso será monitoreado y registrado.${reset}\n"
}

# ==============================
# Helpers
# ==============================
solo_usuarios_ssh() {
    awk -F: '$3 >= 1000 && $1!="nobody" {print $1}' /etc/passwd
}

pausa() {
    echo -ne "${c4}ENTER para continuar...${reset} "
    read _
}

# ==============================
# Funciones principales
# ==============================
crear_usuario() {
    echo -ne "${c2}👤 Usuario:${reset} "
    read user
    echo -ne "${c3}🔑 Contraseña:${reset} "
    read pass
    echo -ne "${c4}📅 Días de duración:${reset} "
    read dias

    expira=$(date -d "+$dias days" +"%Y-%m-%d")
    useradd -e "$expira" -M -s /bin/false "$user"
    echo "$user:$pass" | chpasswd

    mkdir -p /root/usuarios_ssh
    cat <<EOF > /root/usuarios_ssh/$user.txt
===== SSH BURGOS =====
Usuario: $user
Contraseña: $pass
Expira: $expira
IP: $IP
Puerto SSH: ${SSH_PORT:-22}
Puerto SSL: ${SSL_PORT:-444}
======================
EOF
    echo -e "${c3}✅ Usuario SSH creado. Archivo:${reset} ${c2}/root/usuarios_ssh/$user.txt${reset}"
}

editar_usuario() {
    mapfile -t usuarios < <(solo_usuarios_ssh)
    usuarios+=("Cancelar")
    PS3=$(echo -e "${c6}Seleccione usuario a editar:${reset} ")

    select user in "${usuarios[@]}"; do
        [[ -z "$user" ]] && echo -e "${danger}Opción inválida${reset}" && continue
        [[ "$user" == "Cancelar" ]] && break
        if id "$user" &>/dev/null; then
            echo -ne "${c3}🔑 Nueva contraseña:${reset} "
            read pass
            echo -ne "${c4}📅 Nuevos días:${reset} "
            read dias
            expira=$(date -d "+$dias days" +"%Y-%m-%d")
            echo "$user:$pass" | chpasswd
            chage -E "$expira" "$user"
            echo -e "${c3}✅ Usuario editado. Expira:${reset} ${c2}$expira${reset}"
            break
        fi
    done
}

listar_usuarios() {
    echo -e "\n${c2}👥 Usuarios SSH:${reset}"
    for u in $(solo_usuarios_ssh); do
        echo -e "${c1} - ${reset}${c5}$u${reset}"
    done
}

bloquear_usuario() {
    mapfile -t usuarios < <(solo_usuarios_ssh)
    usuarios+=("Cancelar")
    PS3=$(echo -e "${c6}Seleccione usuario a bloquear:${reset} ")

    select user in "${usuarios[@]}"; do
        [[ -z "$user" ]] && echo -e "${danger}Opción inválida${reset}" && continue
        [[ "$user" == "Cancelar" ]] && break
        if id "$user" &>/dev/null; then
            passwd -l "$user" >/dev/null 2>&1
            echo -e "${c4}🔒 Usuario bloqueado:${reset} ${c2}$user${reset}"
            break
        fi
    done
}

desbloquear_usuario() {
    mapfile -t usuarios < <(solo_usuarios_ssh)
    usuarios+=("Cancelar")
    PS3=$(echo -e "${c6}Seleccione usuario a desbloquear:${reset} ")

    select user in "${usuarios[@]}"; do
        [[ -z "$user" ]] && echo -e "${danger}Opción inválida${reset}" && continue
        [[ "$user" == "Cancelar" ]] && break
        if id "$user" &>/dev/null; then
            passwd -u "$user" >/dev/null 2>&1
            echo -e "${c3}🔓 Usuario desbloqueado:${reset} ${c2}$user${reset}"
            break
        fi
    done
}

eliminar_usuario() {
    mapfile -t usuarios < <(solo_usuarios_ssh)
    usuarios+=("Cancelar")
    PS3=$(echo -e "${danger}Seleccione usuario a ELIMINAR:${reset} ")

    select user in "${usuarios[@]}"; do
        [[ -z "$user" ]] && echo -e "${danger}Opción inválida${reset}" && continue
        [[ "$user" == "Cancelar" ]] && break
        if id "$user" &>/dev/null; then
            userdel -r "$user" 2>/dev/null
            rm -f "/root/usuarios_ssh/$user.txt"
            echo -e "${danger}🗑 Usuario eliminado:${reset} ${c2}$user${reset}"
            break
        fi
    done
}

# ==============================
# Funciones nuevas
# ==============================
monitorear_usuarios() {
    echo -e "\n${c2}📊 Usuarios conectados actualmente:${reset}\n"
    who
    echo -e "\n${c3}Conexiones activas por IP:${reset}\n"
    ss -tn state established | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr
}

reiniciar_servicios() {
    echo -e "\n${c4}🔄 Reiniciando servicios SSH y Stunnel...${reset}"
    systemctl restart ssh >/dev/null 2>&1
    systemctl restart stunnel4 >/dev/null 2>&1
    echo -e "${c3}✅ Servicios reiniciados correctamente${reset}"
}

cambiar_puerto_ssh() {
    echo -ne "${c2}🔧 Nuevo puerto SSH:${reset} "
    read nuevo_puerto
    if [[ ! $nuevo_puerto =~ ^[0-9]+$ ]]; then
        echo -e "${danger}❌ Puerto inválido${reset}"
        return
    fi
    sed -i "s/^#\?Port .*/Port $nuevo_puerto/" /etc/ssh/sshd_config
    systemctl restart ssh
    echo -e "${c3}✅ Puerto SSH cambiado a:${reset} ${c2}$nuevo_puerto${reset}"
}

info_servidor() {
    echo -e "\n${c2}💻 Información del servidor:${reset}\n"
    echo -e "${c3}Hostname:${reset} $(hostname)"
    echo -e "${c3}IP Pública:${reset} $IP"
    echo -e "${c3}Puerto SSH:${reset} ${SSH_PORT:-22}"
    echo -e "${c3}Puerto SSL:${reset} ${SSL_PORT:-444}"
    echo -e "${c3}Sistema:${reset} $(lsb_release -d 2>/dev/null | cut -f2)"
    echo -e "${c3}Kernel:${reset} $(uname -r)"
    echo -e "${c3}Uptime:${reset} $(uptime -p)"
    echo -e "${c3}RAM Libre:${reset} $(free -m | awk '/Mem:/ {print $4" MB"}')"
}

# ==============================
# GESTIÓN DE PUERTOS
# ==============================
abrir_puerto() {
    echo -ne "${c2}🔧 Puerto a ABRIR:${reset} "
    read puerto
    if [[ ! $puerto =~ ^[0-9]+$ ]]; then
        echo -e "${danger}❌ Puerto inválido${reset}"
        return
    fi
    ufw allow $puerto >/dev/null 2>&1
    echo -e "${c3}✅ Puerto abierto:${reset} ${c2}$puerto${reset}"
}

cerrar_puerto() {
    echo -ne "${c2}🔧 Puerto a CERRAR:${reset} "
    read puerto
    if [[ ! $puerto =~ ^[0-9]+$ ]]; then
        echo -e "${danger}❌ Puerto inválido${reset}"
        return
    fi
    ufw deny $puerto >/dev/null 2>&1
    echo -e "${c3}🚫 Puerto cerrado:${reset} ${c2}$puerto${reset}"
}

gestionar_puertos() {
    while true; do
        echo -e "\n${c6}===== GESTIÓN DE PUERTOS =====${reset}"
        echo -e "${c2}1) Abrir puerto${reset}"
        echo -e "${c3}2) Cerrar puerto${reset}"
        echo -e "${c4}3) Ver puertos abiertos${reset}"
        echo -e "${c5}4) Volver al menú principal${reset}"
        echo -ne "${c6}Seleccione:${reset} "
        read op
        case $op in
            1) abrir_puerto ;;
            2) cerrar_puerto ;;
            3) ufw status ;;
            4) break ;;
            *) echo -e "${danger}❌ Opción inválida${reset}" ;;
        esac
    done
}

# ==============================
# Menú principal
# ==============================
while true; do
    banner
    echo -e "${c6}===== MENU VPS BURGOS =====${reset}"
    echo -e "${c2}1) Crear usuario SSH${reset}"
    echo -e "${c3}2) Editar usuario SSH${reset}"
    echo -e "${c4}3) Listar usuarios SSH${reset}"
    echo -e "${c5}4) Bloquear usuario SSH${reset}"
    echo -e "${c6}5) Desbloquear usuario SSH${reset}"
    echo -e "${danger}6) Eliminar usuario SSH${reset}"
    echo -e "${c5}7) Monitorear usuarios activos${reset}"
    echo -e "${c4}8) Reiniciar servicios SSH/SSL${reset}"
    echo -e "${c2}9) Cambiar puerto SSH${reset}"
    echo -e "${c3}10) Información del servidor${reset}"
    echo -e "${c2}11) Gestionar puertos (abrir/cerrar)${reset}"
    echo -e "${c6}12) Salir${reset}"
    echo -e "${c6}==========================${reset}"

    echo -ne "${c6}Seleccione:${reset} "
    read opcion
    case $opcion in
        1) crear_usuario ;;
        2) editar_usuario ;;
        3) listar_usuarios ;;
        4) bloquear_usuario ;;
        5) desbloquear_usuario ;;
        6) eliminar_usuario ;;
        7) monitorear_usuarios ;;
        8) reiniciar_servicios ;;
        9) cambiar_puerto_ssh ;;
        10) info_servidor ;;
        11) gestionar_puertos ;;
        12) exit ;;
        *) echo -e "${danger}❌ Opción inválida${reset}" ;;
    esac
    pausa
done
