#!/bin/bash
# ===================================
#  VPS BURGOS - Instalador Automático
#  install.sh
# ===================================

set -e

# --- COLORES ---
c1="\e[38;5;54m"
c2="\e[38;5;93m"
c3="\e[38;5;177m"
c4="\e[38;5;183m"
c5="\e[38;5;141m"
c6="\e[38;5;219m"
danger="\e[38;5;196m"
reset="\e[0m"
bold="\e[1m"

echo -e "${c6}>>> VPS BURGOS - Instalando todo automáticamente...${reset}"

# ------------------------
# INSTALAR STUNNEL
# ------------------------
echo -e "${c2}[1/5] Instalando stunnel4...${reset}"
apt update -y
apt install -y stunnel4 openssl

echo -e "${c2}[2/5] Generando certificado autofirmado...${reset}"
openssl req -new -x509 -days 365 -nodes -subj "/CN=stunnel" \
    -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem
chmod 600 /etc/stunnel/stunnel.pem

echo -e "${c2}[3/5] Configurando stunnel...${reset}"
cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no

[ssh]
accept = 443
connect = 22
EOF

mkdir -p /var/run/stunnel4
chown stunnel4:stunnel4 /var/run/stunnel4

sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
systemctl restart stunnel4
systemctl enable stunnel4

# ------------------------
# MENÚ VPS BURGOS
# ------------------------
echo -e "${c2}[4/5] Instalando menú de gestión VPS Burgos...${reset}"

cat > /usr/local/bin/menu <<'EOF'
#!/bin/bash
# ==============================
#   VPS BURGOS - MANAGER SSH
# ==============================

# Detectar IP y puertos
IP=$(hostname -I | awk '{print $1}')
SSH_PORT=$(ss -tlnp 2>/dev/null | grep -m1 sshd | awk '{print $4}' | sed 's/.*://')
SSL_PORT=$(ss -tlnp 2>/dev/null | grep stunnel | awk '{print $4}' | sed 's/.*://')

# Colores
c1="\e[38;5;54m"; c2="\e[38;5;93m"; c3="\e[38;5;177m"
c4="\e[38;5;183m"; c5="\e[38;5;141m"; c6="\e[38;5;219m"
danger="\e[38;5;196m"; reset="\e[0m"; bold="\e[1m"

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

solo_usuarios_ssh() { awk -F: '$3 >= 1000 && $1!="nobody" {print $1}' /etc/passwd; }
pausa() { echo -ne "${c4}ENTER para continuar...${reset} "; read _; }

crear_usuario() {
    echo -ne "${c2}👤 Usuario:${reset} "; read user
    echo -ne "${c3}🔑 Contraseña:${reset} "; read pass
    echo -ne "${c4}📅 Días de duración:${reset} "; read dias
    expira=$(date -d "+$dias days" +"%Y-%m-%d")
    useradd -e "$expira" -M -s /bin/false "$user"
    echo "$user:$pass" | chpasswd
    mkdir -p /root/usuarios_ssh
    cat <<INFO > /root/usuarios_ssh/$user.txt
===== SSH BURGOS =====
Usuario: $user
Contraseña: $pass
Expira: $expira
IP: $IP
Puerto SSH: ${SSH_PORT:-22}
Puerto SSL: ${SSL_PORT:-444}
======================
INFO
    echo -e "${c3}✅ Usuario SSH creado. Archivo:${reset} ${c2}/root/usuarios_ssh/$user.txt${reset}"
}

editar_usuario() {
    mapfile -t usuarios < <(solo_usuarios_ssh); usuarios+=("Cancelar")
    PS3=$(echo -e "${c6}Seleccione usuario a editar:${reset} ")
    select user in "${usuarios[@]}"; do
        [[ "$user" == "Cancelar" ]] && break
        if id "$user" &>/dev/null; then
            echo -ne "${c3}🔑 Nueva contraseña:${reset} "; read pass
            echo -ne "${c4}📅 Nuevos días:${reset} "; read dias
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
    mapfile -t usuarios < <(solo_usuarios_ssh); usuarios+=("Cancelar")
    PS3=$(echo -e "${c6}Seleccione usuario a bloquear:${reset} ")
    select user in "${usuarios[@]}"; do
        [[ "$user" == "Cancelar" ]] && break
        passwd -l "$user" && echo -e "${c4}🔒 Usuario bloqueado:${reset} ${c2}$user${reset}" && break
    done
}

desbloquear_usuario() {
    mapfile -t usuarios < <(solo_usuarios_ssh); usuarios+=("Cancelar")
    PS3=$(echo -e "${c6}Seleccione usuario a desbloquear:${reset} ")
    select user in "${usuarios[@]}"; do
        [[ "$user" == "Cancelar" ]] && break
        passwd -u "$user" && echo -e "${c3}🔓 Usuario desbloqueado:${reset} ${c2}$user${reset}" && break
    done
}

eliminar_usuario() {
    mapfile -t usuarios < <(solo_usuarios_ssh); usuarios+=("Cancelar")
    PS3=$(echo -e "${danger}Seleccione usuario a ELIMINAR:${reset} ")
    select user in "${usuarios[@]}"; do
        [[ "$user" == "Cancelar" ]] && break
        userdel -r "$user" && rm -f "/root/usuarios_ssh/$user.txt"
        echo -e "${danger}🗑 Usuario eliminado:${reset} ${c2}$user${reset}" && break
    done
}

while true; do
    banner
    echo -e "${c6}===== MENU VPS BURGOS =====${reset}"
    echo -e "${c2}1) Crear usuario SSH${reset}"
    echo -e "${c3}2) Editar usuario SSH${reset}"
    echo -e "${c4}3) Listar usuarios SSH${reset}"
    echo -e "${c5}4) Bloquear usuario SSH${reset}"
    echo -e "${c6}5) Desbloquear usuario SSH${reset}"
    echo -e "${danger}6) Eliminar usuario SSH${reset}"
    echo -e "${c6}7) Salir${reset}"
    echo -ne "${c6}Seleccione:${reset} "; read opcion
    case $opcion in
        1) crear_usuario ;;
        2) editar_usuario ;;
        3) listar_usuarios ;;
        4) bloquear_usuario ;;
        5) desbloquear_usuario ;;
        6) eliminar_usuario ;;
        7) exit ;;
        *) echo -e "${danger}❌ Opción inválida${reset}" ;;
    esac
    pausa
done
EOF

chmod +x /usr/local/bin/menu

# ------------------------
# BANNER DE SSH
# ------------------------
echo -e "${c2}[5/5] Configurando banner SSH...${reset}"

cat > /etc/issue.net <<EOF
================================
🔒 Bienvenido a VPS Burgos
---- Tu conexión segura ----
================================
📱 WhatsApp: 9851169633
📬 Telegram: @Escanor_Sama18
================================
⚠ Acceso autorizado únicamente.
🚨 Todo acceso será monitoreado y registrado.
================================
EOF

grep -q "Banner /etc/issue.net" /etc/ssh/sshd_config || echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
systemctl restart ssh

echo -e "\n${c6}✅ Instalación completa.${reset}"
echo -e "${c3}Ejecuta el menú con:${reset} ${c2}menu${reset}\n"