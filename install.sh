#!/bin/bash
# ============================================
#   🚀 Instalador Burgos VPS Menu Multicolor
#   Autor: Burgos & ChatGPT
# ============================================

set -e

INSTALL_PATH="/usr/local/bin/menu"
SCRIPT_PATH="/usr/local/bin/menu_admin.sh"
MOTD_FILE="/etc/motd"

# ================================
# Crear script principal del menú
# ================================
cat <<'EOF' > $SCRIPT_PATH
#!/bin/bash
# ============================================
#        🚀 BURGOS VPS MENU MULTICOLOR 🚀
# ============================================

# -------- Colores --------
violeta="\e[1;35m"
verde="\e[1;32m"
rojo="\e[1;31m"
azul="\e[1;34m"
cyan="\e[1;36m"
amarillo="\e[1;33m"
blanco="\e[1;37m"
reset="\e[0m"

# -------- Utilidades --------
pausa() { echo; read -p "Presione Enter para continuar..." _; }
valida_puerto() {
  [[ "$1" =~ ^[0-9]+$ ]] && (( $1>=1 && $1<=65535 ))
}
existe_cmd() { command -v "$1" &>/dev/null; }
backup_conf() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  cp -a "$f" "${f}.bak-$(date +%F-%H%M%S)"
}

banner() {
  clear
  echo -e "${violeta}╔════════════════════════════════════════╗${reset}"
  echo -e "${violeta}     🚀  Ningún Sistema es Seguro  🚀     ${reset}"
  echo -e "${violeta}╚════════════════════════════════════════╝${reset}"
  echo
}

# ============================================
# 👤 Gestión de Usuarios
# ============================================
crear_usuario() {
  echo -ne "👤 ${cyan}Nombre de usuario:${reset} "; read usuario
  echo -ne "🔑 ${azul}Contraseña:${reset} "; read -s clave; echo
  echo -ne "⏳ ${amarillo}Días de validez:${reset} "; read dias
  if ! [[ "$dias" =~ ^[0-9]+$ ]]; then
    echo -e "${rojo}⚠ Días inválidos.${reset}"; return
  fi
  # Crear con expiración
  useradd -m -s /bin/bash -e "$(date -d "+$dias days" +%Y-%m-%d)" "$usuario"
  echo "$usuario:$clave" | chpasswd
  echo -e "${verde}✔ Usuario ${blanco}$usuario${reset} creado. Expira en ${amarillo}$dias${reset} días."
}

quitar_usuario() {
  echo -ne "👤 ${amarillo}Usuario a eliminar:${reset} "; read usuario
  if id "$usuario" &>/dev/null; then
    userdel -r "$usuario"
    echo -e "${rojo}✘ Usuario ${blanco}$usuario${reset} eliminado."
  else
    echo -e "${rojo}⚠ El usuario no existe.${reset}"
  fi
}

editar_pass() {
  echo -ne "👤 ${cyan}Usuario:${reset} "; read usuario
  if ! id "$usuario" &>/dev/null; then
    echo -e "${rojo}⚠ El usuario no existe.${reset}"; return
  fi
  echo -ne "🔑 ${azul}Nueva contraseña:${reset} "; read -s clave; echo
  echo "$usuario:$clave" | chpasswd
  echo -e "${verde}✔ Contraseña actualizada para ${blanco}$usuario${reset}."
}

renovar_usuario() {
  echo -ne "👤 ${cyan}Usuario a renovar:${reset} "; read usuario
  if ! id "$usuario" &>/dev/null; then
    echo -e "${rojo}⚠ El usuario no existe.${reset}"; return
  fi
  echo -ne "➕ ${amarillo}Días adicionales:${reset} "; read dias
  if ! [[ "$dias" =~ ^[0-9]+$ ]]; then
    echo -e "${rojo}⚠ Días inválidos.${reset}"; return
  fi
  chage -E "$(date -d "+$dias days" +%Y-%m-%d)" "$usuario"
  echo -e "${verde}♻️ Usuario ${blanco}$usuario${reset} renovado por ${amarillo}$dias${reset} días."
}

eliminar_caducados() {
  echo -e "${rojo}🗑️ Eliminando usuarios caducados...${reset}"
  while IFS=: read -r u _ uid _ _ _ _; do
    # evitar usuarios del sistema (uid < 1000) y especiales
    [[ "$uid" -lt 1000 ]] && continue
    exp="$(chage -l "$u" 2>/dev/null | awk -F': ' '/Account expires/{print $2}')"
    [[ -z "$exp" || "$exp" == "never" ]] && continue
    exp_s=$(date -d "$exp" +%s 2>/dev/null || echo 0)
    now_s=$(date +%s)
    if (( exp_s>0 && exp_s<now_s )); then
      userdel -r "$u" && echo "   Eliminado: $u"
    fi
  done < /etc/passwd
  echo -e "${verde}✔ Limpieza finalizada.${reset}"
}

listar_usuarios() {
  echo -e "${azul}📋 Usuarios con home (UID >= 1000):${reset}"
  awk -F: '$3>=1000 {print " - " $1}' /etc/passwd
}

monitorear_conectados() {
  echo -e "${amarillo}👀 Usuarios conectados (who):${reset}"
  who || echo "Sin sesiones activas."
}

menu_usuarios() {
  while true; do
    banner
    echo -e "${verde}════════════════════════════════════════════${reset}"
    echo -e "   ${cyan}👥 Gestión de Usuarios SSH${reset}"
    echo -e "${verde}════════════════════════════════════════════${reset}"
    echo -e "${cyan}[1]${reset} ➕ Crear nuevo usuario"
    echo -e "${amarillo}[2]${reset} ➖ Quitar usuario"
    echo -e "${azul}[3]${reset} ✏️ Cambiar contraseña"
    echo -e "${verde}[4]${reset} ♻️ Renovar usuario (días)"
    echo -e "${rojo}[5]${reset} 🗑️ Eliminar usuarios caducados"
    echo -e "${violeta}[6]${reset} 📋 Listar usuarios"
    echo -e "${amarillo}[7]${reset} 👀 Usuarios conectados"
    echo -e "${rojo}[0]${reset} 🔙 Atrás"
    echo
    echo -ne "${amarillo}Seleccione una opción:${reset} "; read op
    case "$op" in
      1) crear_usuario; pausa ;;
      2) quitar_usuario; pausa ;;
      3) editar_pass; pausa ;;
      4) renovar_usuario; pausa ;;
      5) eliminar_caducados; pausa ;;
      6) listar_usuarios; pausa ;;
      7) monitorear_conectados; pausa ;;
      0) break ;;
      *) echo -e "${rojo}⚠ Opción no válida.${reset}"; sleep 1 ;;
    esac
  done
}

# ============================================
# 🔧 Herramientas del sistema
# ============================================
estado_sistema() {
  echo -e "${verde}➤ Uptime:${reset}"; uptime
  echo -e "${verde}➤ Memoria:${reset}"; free -h
  echo -e "${verde}➤ Disco raíz:${reset}"; df -h /
}

menu_herramientas() {
  while true; do
    banner
    echo -e "${cyan}[1]${reset} 🔄 Reiniciar VPS"
    echo -e "${verde}[2]${reset} 📊 Estado del sistema"
    echo -e "${violeta}[0]${reset} 🔙 Atrás"
    echo
    echo -ne "${amarillo}Seleccione una opción:${reset} "; read op
    case "$op" in
      1) echo -e "${rojo}Reiniciando VPS...${reset}"; reboot ;;
      2) estado_sistema; pausa ;;
      0) break ;;
      *) echo -e "${rojo}⚠ Opción no válida.${reset}"; sleep 1 ;;
    esac
  done
}

# ============================================
# ⚙️ Gestión de Puertos (multi-servicio)
# ============================================

# --- SSH (OpenSSH) ---
ssh_list_ports() {
  grep -E '^\s*Port\s+[0-9]+' /etc/ssh/sshd_config 2>/dev/null || echo "(sin líneas Port)"
}
ssh_add_port() {
  local p="$1"
  backup_conf /etc/ssh/sshd_config
  # Evitar duplicados
  grep -qE "^\s*Port\s+$p\b" /etc/ssh/sshd_config 2>/dev/null || echo "Port $p" >> /etc/ssh/sshd_config
  systemctl restart sshd 2>/dev/null || service ssh restart 2>/dev/null
}
ssh_del_port() {
  local p="$1"
  backup_conf /etc/ssh/sshd_config
  sed -ri "/^\s*Port\s+$p\b/d" /etc/ssh/sshd_config
  systemctl restart sshd 2>/dev/null || service ssh restart 2>/dev/null
}

# --- Dropbear ---
dropbear_conf="/etc/default/dropbear"
dropbear_list_ports() {
  if [[ -f "$dropbear_conf" ]]; then
    line=$(grep -E '^DROPBEAR_EXTRA_ARGS=' "$dropbear_conf" | head -n1)
    [[ -z "$line" ]] && echo "(sin DROPBEAR_EXTRA_ARGS; usa puerto por defecto)" && return
    echo "$line" | grep -oE '\-p[ ]*[0-9]+' | awk '{print $2}' | sed 's/^/-p /' || echo "(sin -p definidos)"
  else
    echo "(Dropbear no instalado)"
  fi
}
dropbear_add_port() {
  local p="$1"
  [[ -f "$dropbear_conf" ]] || { echo "(Dropbear no instalado)"; return; }
  backup_conf "$dropbear_conf"
  if grep -qE '^DROPBEAR_EXTRA_ARGS=' "$dropbear_conf"; then
    # añadir -p si no está
    grep -qE "\-p[ ]*$p(\b| )" "$dropbear_conf" || sed -ri "s|^DROPBEAR_EXTRA_ARGS=\"?([^\"]*)\"?$|DROPBEAR_EXTRA_ARGS=\"\1 -p $p\"|g" "$dropbear_conf"
  else
    echo "DROPBEAR_EXTRA_ARGS=\"-p $p\"" >> "$dropbear_conf"
  fi
  systemctl restart dropbear 2>/dev/null || service dropbear restart 2>/dev/null
}
dropbear_del_port() {
  local p="$1"
  [[ -f "$dropbear_conf" ]] || { echo "(Dropbear no instalado)"; return; }
  backup_conf "$dropbear_conf"
  sed -ri "s/(DROPBEAR_EXTRA_ARGS=\"?[^\"]*)-p[ ]*$p(\b| )/\1/g" "$dropbear_conf"
  # limpiar dobles espacios y comillas
  sed -ri 's/DROPBEAR_EXTRA_ARGS=" +/DROPBEAR_EXTRA_ARGS="/; s/  +/ /g' "$dropbear_conf"
  systemctl restart dropbear 2>/dev/null || service dropbear restart 2>/dev/null
}

# --- OpenVPN (server principal) ---
openvpn_conf="/etc/openvpn/server.conf"
openvpn_list_port() {
  if [[ -f "$openvpn_conf" ]]; then
    grep -E '^\s*port\s+[0-9]+' "$openvpn_conf" || echo "(sin línea port; por defecto 1194)"
  else
    # Ubuntu 20.04+/Debian puede usar /etc/openvpn/server/server.conf
    if [[ -f /etc/openvpn/server/server.conf ]]; then
      openvpn_conf="/etc/openvpn/server/server.conf"
      grep -E '^\s*port\s+[0-9]+' "$openvpn_conf" || echo "(sin línea port; por defecto 1194)"
    else
      echo "(OpenVPN no instalado)"
    fi
  fi
}
openvpn_set_port() {
  local p="$1"
  # localizar conf
  if [[ ! -f "$openvpn_conf" ]]; then
    if [[ -f /etc/openvpn/server/server.conf ]]; then
      openvpn_conf="/etc/openvpn/server/server.conf"
    else
      echo "(OpenVPN no instalado)"; return
    fi
  fi
  backup_conf "$openvpn_conf"
  if grep -qE '^\s*port\s+[0-9]+' "$openvpn_conf"; then
    sed -ri "s/^\s*port\s+[0-9]+/port $p/" "$openvpn_conf"
  else
    echo "port $p" >> "$openvpn_conf"
  fi
  systemctl restart openvpn-server@server 2>/dev/null || systemctl restart openvpn 2>/dev/null || service openvpn restart 2>/dev/null
}

# ---- Menú de cada servicio ----
menu_puertos_ssh() {
  while true; do
    banner
    echo -e "🔌 ${cyan}SSH (OpenSSH)${reset}"
    echo -e "${verde}Puertos actuales:${reset}"; ssh_list_ports; echo
    echo -e "${cyan}[1]${reset} ➕ Agregar puerto"
    echo -e "${amarillo}[2]${reset} ➖ Quitar puerto"
    echo -e "${violeta}[0]${reset} 🔙 Atrás"
    echo
    echo -ne "${amarillo}Seleccione:${reset} "; read op
    case "$op" in
      1) echo -ne "Nuevo puerto: "; read p; valida_puerto "$p" && ssh_add_port "$p" || echo -e "${rojo}⚠ Puerto inválido.${reset}"; pausa ;;
      2) echo -ne "Puerto a quitar: "; read p; valida_puerto "$p" && ssh_del_port "$p" || echo -e "${rojo}⚠ Puerto inválido.${reset}"; pausa ;;
      0) break ;;
      *) echo -e "${rojo}⚠ Opción no válida.${reset}"; sleep 1 ;;
    esac
  done
}

menu_puertos_dropbear() {
  if ! existe_cmd dropbearkey && [[ ! -f "$dropbear_conf" ]]; then
    echo -e "${rojo}❌ Dropbear no parece estar instalado.${reset}"; pausa; return
  fi
  while true; do
    banner
    echo -e "🔌 ${cyan}Dropbear${reset}"
    echo -e "${verde}Puertos actuales:${reset}"; dropbear_list_ports; echo
    echo -e "${cyan}[1]${reset} ➕ Agregar puerto"
    echo -e "${amarillo}[2]${reset} ➖ Quitar puerto"
    echo -e "${violeta}[0]${reset} 🔙 Atrás"
    echo
    echo -ne "${amarillo}Seleccione:${reset} "; read op
    case "$op" in
      1) echo -ne "Nuevo puerto: "; read p; valida_puerto "$p" && dropbear_add_port "$p" || echo -e "${rojo}⚠ Puerto inválido.${reset}"; pausa ;;
      2) echo -ne "Puerto a quitar: "; read p; valida_puerto "$p" && dropbear_del_port "$p" || echo -e "${rojo}⚠ Puerto inválido.${reset}"; pausa ;;
      0) break ;;
      *) echo -e "${rojo}⚠ Opción no válida.${reset}"; sleep 1 ;;
    esac
  done
}

menu_puertos_openvpn() {
  # mostrar aviso si no instalado
  if [[ ! -f "$openvpn_conf" && ! -f /etc/openvpn/server/server.conf ]]; then
    echo -e "${rojo}❌ OpenVPN no parece estar instalado.${reset}"; pausa; return
  fi
  while true; do
    banner
    echo -e "🔌 ${cyan}OpenVPN (servidor principal)${reset}"
    echo -e "${verde}Puerto actual:${reset}"; openvpn_list_port; echo
    echo -e "${cyan}[1]${reset} 🔁 Cambiar puerto del servidor"
    echo -e "${violeta}[0]${reset} 🔙 Atrás"
    echo
    echo -ne "${amarillo}Seleccione:${reset} "; read op
    case "$op" in
      1) echo -ne "Nuevo puerto: "; read p; valida_puerto "$p" && openvpn_set_port "$p" && echo -e "${verde}✔ Puerto actualizado.${reset}" || echo -e "${rojo}⚠ Puerto inválido.${reset}"; pausa ;;
      0) break ;;
      *) echo -e "${rojo}⚠ Opción no válida.${reset}"; sleep 1 ;;
    esac
  done
}

menu_puertos() {
  while true; do
    banner
    echo -e "${azul}════════════════════════════════════════════${reset}"
    echo -e "   ${cyan}⚙️  Configuración de Puertos${reset}"
    echo -e "${azul}════════════════════════════════════════════${reset}"
    echo -e "${cyan}[1]${reset} SSH (OpenSSH)"
    echo -e "${amarillo}[2]${reset} Dropbear"
    echo -e "${verde}[3]${reset} OpenVPN (server)"
    echo -e "${violeta}[0]${reset} 🔙 Atrás"
    echo
    echo -ne "${amarillo}Seleccione un servicio:${reset} "; read svc
    case "$svc" in
      1) menu_puertos_ssh ;;
      2) menu_puertos_dropbear ;;
      3) menu_puertos_openvpn ;;
      0) break ;;
      *) echo -e "${rojo}⚠ Opción no válida.${reset}"; sleep 1 ;;
    esac
  done
}

# ============================================
# 📌 Menú principal
# ============================================
menu_principal() {
  while true; do
    banner
    echo -e "${cyan}[1]${reset} 👤 Gestionar usuarios SSH"
    echo -e "${amarillo}[2]${reset} 🔧 Herramientas del sistema"
    echo -e "${azul}[3]${reset} 🔌 Configuración de puertos"
    echo -e "${rojo}[0]${reset} ❌ Salir"
    echo
    echo -ne "${amarillo}Seleccione una opción:${reset} "; read opcion
    case "$opcion" in
      1) menu_usuarios ;;
      2) menu_herramientas ;;
      3) menu_puertos ;;
      0) echo -e "${violeta}👋 Saliendo...${reset}"; exit 0 ;;
      *) echo -e "${rojo}⚠ Opción no válida.${reset}"; sleep 1 ;;
    esac
  done
}

# ================================
# ▶️ Iniciar menú
# ================================
menu_principal
EOF

chmod +x "$SCRIPT_PATH"

# ================================
# Crear acceso global "menu"
# ================================
cat > "$INSTALL_PATH" <<EOF
#!/bin/bash
"$SCRIPT_PATH"
EOF
chmod +x "$INSTALL_PATH"

# ================================
# Configurar mensaje de bienvenida MOTD
# ================================
cat <<'EOM' > "$MOTD_FILE"
[95m╔══════════════════════════════╗[0m
[95m   🚀  Bienvenido a VPS BURGOS 🚀[0m
[95m╚══════════════════════════════╝[0m
 Soporte: [96m@Escanor_Sama18[0m
EOM

# ================================
# Ejecutar menú al iniciar sesión (root)
# ================================
if ! grep -q "^menu$" /root/.bashrc 2>/dev/null; then
  echo "menu" >> /root/.bashrc
fi

echo "✅ Instalación completada. Escribe 'menu' para abrir el panel."
