#!/bin/bash
set -e

# ==============================
#  Instalador - VPS BURGOS (Clientes)
# ==============================

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Este instalador debe ejecutarse como root."
    exit 1
  fi
}
require_root

echo ">>> Actualizando e instalando dependencias..."
apt update -y
apt install -y openssh-server stunnel4 iproute2 curl jq sed awk

# ==============================
# Configurar stunnel (443 -> 22)
# ==============================
echo ">>> Configurando stunnel..."
mkdir -p /etc/stunnel

if [[ ! -f /etc/stunnel/stunnel.pem ]]; then
  echo ">>> Generando certificado autofirmado para stunnel..."
  openssl req -new -x509 -days 365 -nodes -subj "/CN=stunnel" \
    -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem
  chmod 600 /etc/stunnel/stunnel.pem
fi

cat > /etc/stunnel/stunnel.conf <<'EOF'
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no

[ssh]
accept = 443
connect = 22
EOF

mkdir -p /var/run/stunnel4
chown stunnel4:stunnel4 /var/run/stunnel4

# Activar stunnel al arranque
sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/stunnel4 || true
systemctl restart stunnel4
systemctl enable stunnel4

# ==============================
# Banner SSH (issue.net)
# ==============================
echo ">>> Configurando banner SSH..."
cat > /etc/issue.net <<'EOF'
\e[38;5;46m================================
🔒 \e[38;5;82mBienvenido a VPS Burgos
\e[38;5;118m---- Tu conexión segura ----
\e[38;5;154m================================
📱 WhatsApp: \e[38;5;190m9851169633
📬 Telegram: \e[38;5;226m@Escanor_Sama18
\e[38;5;201m================================
⚠ \e[38;5;207mAcceso autorizado únicamente.
\e[38;5;213mTodo acceso será monitoreado y registrado.
\e[38;5;219m================================\e[0m
EOF

# Activar uso de banner en sshd
if ! grep -q '^Banner /etc/issue.net' /etc/ssh/sshd_config; then
  echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
fi
systemctl restart ssh

# ==============================
# Config de Burgos (para key opcional)
# ==============================
echo ">>> Creando config de Burgos..."
mkdir -p /etc/burgos
cat > /etc/burgos/config <<'EOF'
# KEY_CHECK_URL: URL de validación de keys (tu VPS personal con generador)
# Ejemplo: https://TU-DOMINIO-O-IP/validate?key=
# Si está vacío, NO se pedirá key.
KEY_CHECK_URL=""

# Mensaje que verá el usuario si la key no es válida
KEY_FAIL_MSG="❌ Key inválida o ya usada. Contacta al soporte."
EOF

# ==============================
# Script del menú
# ==============================
echo ">>> Instalando menú..."
cat > /usr/local/bin/menu <<'EOF'
#!/bin/bash

# ==============================
#   VPS BURGOS - MANAGER SSH
# ==============================

#--- Cargar config (key opcional) ---
CONF="/etc/burgos/config"
[ -f "$CONF" ] && source "$CONF"

#--- Validación de key (opcional) ---
validate_key_once() {
  # Si no hay URL, no se valida
  if [[ -z "$KEY_CHECK_URL" ]]; then
    return 0
  fi
  mkdir -p /etc/burgos
  # Si ya fue validada antes, no pedir de nuevo
  if [[ -f /etc/burgos/.key_ok ]]; then
    return 0
  fi
  echo -ne "🔑 Ingrese su KEY: "
  read KEY

  # Permite URLs del tipo:
  #   1) https://host/validate?key=
  #   2) https://host/validate   (enviando POST JSON)
  if [[ "$KEY_CHECK_URL" == *"key="* ]]; then
    RESP=$(curl -fsSL "${KEY_CHECK_URL}${KEY}" || true)
  else
    RESP=$(curl -fsSL -X POST -H "Content-Type: application/json" \
      -d "{\"key\":\"$KEY\",\"host\":\"$(hostname)\",\"ip\":\"$(hostname -I | awk '{print $1}')\"}" \
      "$KEY_CHECK_URL" || true)
  fi

  # Espera JSON con {"ok":true}
  OK=$(echo "$RESP" | jq -r '.ok' 2>/dev/null || echo "false")
  NOTE=$(echo "$RESP" | jq -r '.note // empty' 2>/dev/null || true)

  if [[ "$OK" == "true" ]]; then
    touch /etc/burgos/.key_ok
    [ -n "$NOTE" ] && echo -e "✅ $NOTE"
    return 0
  else
    echo -e "${KEY_FAIL_MSG:-Key inválida.}"
    exit 1
  fi
}

#--- Detección IP/puertos ---
IP=$(hostname -I | awk '{print $1}')
SSH_PORTS() {
  # Puertos configurados/running de SSH
  SSHP_FROM_CFG=$(grep -iE '^Port ' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
  SSHP_FROM_SS=$(ss -tlnp 2>/dev/null | awk '/sshd/ {print $4}' | sed 's/.*://')
  printf "%s\n%s\n" "$SSHP_FROM_CFG" "$SSHP_FROM_SS" | awk 'NF' | sort -n | uniq
}
SSL_PORTS() {
  # Puertos accept en stunnel
  awk -F= '/^[[:space:]]*accept[[:space:]]*=/{gsub(/[[:space:]]/,"",$2); print $2}' /etc/stunnel/stunnel.conf 2>/dev/null | sort -n | uniq
}

# === Colores degradado púrpura ===
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
# Banner
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

ver_puertos() {
    echo -e "\n${c2}🔎 Puertos SSH detectados:${reset}"
    if SSH_LIST=$(SSH_PORTS) && [[ -n "$SSH_LIST" ]]; then
      while read p; do [[ -n "$p" ]] && echo -e " ${c1}-${reset} ${c5}$p${reset}"; done <<< "$SSH_LIST"
    else
      echo -e " ${danger}(ninguno)${reset}"
    fi
    echo -e "\n${c3}🔐 Puertos SSL (stunnel) detectados:${reset}"
    if SSL_LIST=$(SSL_PORTS) && [[ -n "$SSL_LIST" ]]; then
      while read p; do [[ -n "$p" ]] && echo -e " ${c1}-${reset} ${c5}$p${reset}"; done <<< "$SSL_LIST"
    else
      echo -e " ${danger}(ninguno)${reset}"
    fi
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
    # Recolectar puertos actuales
    SSH_JOIN=$(SSH_PORTS | paste -sd "," -)
    SSL_JOIN=$(SSL_PORTS | paste -sd "," -)

    cat <<EOF2 > /root/usuarios_ssh/$user.txt
===== SSH BURGOS =====
Usuario: $user
Contraseña: $pass
Expira: $expira
IP: $IP
Puertos SSH: ${SSH_JOIN:-22}
Puertos SSL: ${SSL_JOIN:-443}
======================
EOF2

    echo -e "\n${c3}✅ Usuario SSH creado.${reset}"
    echo -e "${c2}📄 Datos guardados en:${reset} /root/usuarios_ssh/${user}.txt\n"

    # Mostrar resumen en pantalla
    echo -e "${c6}──── Resumen de la cuenta ────${reset}"
    echo -e " ${c1}IP:${reset}            ${c5}$IP${reset}"
    echo -e " ${c1}Usuario:${reset}       ${c5}$user${reset}"
    echo -e " ${c1}Contraseña:${reset}    ${c5}$pass${reset}"
    echo -e " ${c1}Expira:${reset}        ${c5}$expira${reset}"
    echo -e " ${c1}Puertos SSH:${reset}   ${c5}${SSH_JOIN:-22}${reset}"
    echo -e " ${c1}Puertos SSL:${reset}   ${c5}${SSL_JOIN:-443}${reset}"
    echo -e "${c6}──────────────────────────────${reset}\n"
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
# Menú principal
# ==============================
validate_key_once
while true; do
    banner
    echo -e "${c6}===== MENU VPS BURGOS =====${reset}"
    echo -e "${c2}1) Crear usuario SSH${reset}"
    echo -e "${c3}2) Editar usuario SSH${reset}"
    echo -e "${c4}3) Listar usuarios SSH${reset}"
    echo -e "${c5}4) Bloquear usuario SSH${reset}"
    echo -e "${c6}5) Desbloquear usuario SSH${reset}"
    echo -e "${danger}6) Eliminar usuario SSH${reset}"
    echo -e "${c2}7) Ver puertos abiertos${reset}"
    echo -e "${c6}8) Salir${reset}"
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
        7) ver_puertos ;;
        8) exit ;;
        *) echo -e "${danger}❌ Opción inválida${reset}" ;;
    esac
    pausa
done
EOF
chmod +x /usr/local/bin/menu

# Alias/atajos
ln -sf /usr/local/bin/menu /usr/local/bin/Burgos 2>/dev/null || true
ln -sf /usr/local/bin/menu /usr/local/bin/burgos 2>/dev/null || true

echo ""
echo "✅ Instalación completada."
echo "➡ Ejecuta: menu   (o: Burgos / burgos)"
echo "ℹ Para activar validación de keys, edita: /etc/burgos/config  y define KEY_CHECK_URL."