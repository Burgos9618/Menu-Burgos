#!/bin/bash
# =====================================================
#  Menu Burgos - Instalador completo
#  - Stunnel4 SSL (444,445,446 -> SSH 22)
#  - Menú admin colorido con gestión de usuarios y puertos SSL
#  - MOTD y auto-ejecución del menú
#  Autor: Burgos & ChatGPT
# =====================================================

set -e

INSTALL_PATH="/usr/local/bin/menu"
SCRIPT_PATH="/usr/local/bin/menu_admin.sh"
MOTD_FILE="/etc/motd"
STUNNEL_CONF="/etc/stunnel/stunnel.conf"
STUNNEL_PEM="/etc/stunnel/stunnel.pem"
DEFAULT_SSL_PORTS=("444" "445" "446")

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "❌ Ejecuta como root: sudo -i"
    exit 1
  fi
}

pkg_install() {
  echo "📦 Instalando paquetes..."
  apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install -y stunnel4 openssl net-tools iproute2 grep sed awk coreutils
}

setup_stunnel() {
  echo "🔐 Configurando Stunnel4..."
  # Certificado
  if [[ ! -f "$STUNNEL_PEM" ]]; then
    openssl req -new -x509 -days 1095 -nodes \
      -subj "/C=MX/ST=Burgos/L=VPS/O=Burgos/OU=Menu/CN=localhost" \
      -out "$STUNNEL_PEM" -keyout "$STUNNEL_PEM"
    chmod 600 "$STUNNEL_PEM"
  fi

  # Config por defecto (sin 443 para no chocar con Apache)
  mkdir -p /etc/stunnel
  cat > "$STUNNEL_CONF" <<EOF
# =========================
#   STUNNEL -> SSH (22)
# =========================
pid = /var/run/stunnel/stunnel.pid
cert = $STUNNEL_PEM
foreground = no
client = no
setuid = stunnel4
setgid = stunnel4
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
EOF

  for p in "${DEFAULT_SSL_PORTS[@]}"; do
    cat >> "$STUNNEL_CONF" <<EOF

[ssh-$p]
accept = $p
connect = 22
EOF
  done

  mkdir -p /var/run/stunnel
  chown stunnel4:stunnel4 /var/run/stunnel

  # Habilitar al arranque
  if grep -q '^ENABLED=' /etc/default/stunnel4 2>/dev/null; then
    sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/stunnel4
  else
    echo "ENABLED=1" > /etc/default/stunnel4
  fi

  systemctl enable stunnel4 >/dev/null 2>&1 || true
  systemctl restart stunnel4 || true
  sleep 1
  systemctl is-active --quiet stunnel4 && echo "✅ Stunnel activo" || echo "⚠️ Revisa: journalctl -u stunnel4 -n 50"
}

setup_motd() {
  echo "🖥️ Configurando mensaje de bienvenida (MOTD)..."
  cat > "$MOTD_FILE" <<'EOM'
[95m╔══════════════════════════════╗[0m
[95m   🚀  Bienvenido a VPS BURGOS 🚀[0m
[95m╚══════════════════════════════╝[0m
 Soporte: [96m@Escanor_Sama18[0m
EOM
}

install_menu() {
  echo "🛠️ Instalando menú administrador..."
  cat <<'EOF' > /usr/local/bin/menu_admin.sh
#!/bin/bash
# ==========================
#      BURGOS MENU
# ==========================

# Colores
violeta="\e[1;35m"
verde="\e[1;32m"
rojo="\e[1;31m"
azul="\e[1;34m"
cyan="\e[1;36m"
amarillo="\e[1;33m"
reset="\e[0m"

STUNNEL_CONF="/etc/stunnel/stunnel.conf"

pausa() {
  echo -e "\n${amarillo}Presiona ENTER para continuar...${reset}"
  read
}

titulo() {
  clr="$1"; txt="$2"
  echo -e "${clr}╔══════════════════════════════════════════╗${reset}"
  printf "%b%*s%b\n" "$clr" $(( (42 + ${#txt})/2 )) "  $txt  " "$reset" | sed "s/ /${reset} /g" > /dev/null
  echo -e "${clr}      🚀  $txt  🚀        ${reset}"
  echo -e "${clr}╚══════════════════════════════════════════╝${reset}"
}

# ================================
# UTIL: listar puertos de stunnel
# ================================
listar_puertos_ssl() {
  echo -e "${cyan}Puertos SSL activos en stunnel:${reset}"
  awk '/^\[ssh-/{gsub(/[\[\]]/,""); gsub(/ssh-/,""); printf "  - %s\n",$1}' "$STUNNEL_CONF" 2>/dev/null || echo " (no encontrado)"
}

# ================================
# Submenú: Usuarios SSH
# ================================
usuarios_menu() {
  while true; do
    clear
    echo -e "${violeta}╔══════════════════════════════╗${reset}"
    echo -e "${violeta}   🔑 Gestión de Usuarios SSH   ${reset}"
    echo -e "${violeta}╚══════════════════════════════╝${reset}"
    echo -e "${cyan}[1]${reset} ➤ ${cyan}Crear usuario (con caducidad)${reset}"
    echo -e "${amarillo}[2]${reset} ➤ ${amarillo}Eliminar usuario${reset}"
    echo -e "${azul}[3]${reset} ➤ ${azul}Editar contraseña${reset}"
    echo -e "${verde}[4]${reset} ➤ ${verde}Renovar usuario (días)${reset}"
    echo -e "${rojo}[5]${reset} ➤ ${rojo}Eliminar usuarios caducados${reset}"
    echo -e "${cyan}[6]${reset} ➤ ${cyan}Lista de usuarios (con expiración)${reset}"
    echo -e "${violeta}[0]${reset} ⬅ ${violeta}Volver${reset}"
    echo
    read -p "Seleccione una opción: " op
    case "$op" in
      1)
        echo -e "${cyan}➤ Creando usuario...${reset}"
        read -p "Usuario: " usuario
        read -s -p "Contraseña: " clave; echo
        read -p "Días válidos: " dias
        expira=$(date -d "+$dias days" +%Y-%m-%d)
        useradd -m -e "$expira" -s /bin/bash "$usuario" && echo "$usuario:$clave" | chpasswd
        echo -e "${verde}✔ Usuario ${usuario} creado. Expira: ${expira}${reset}"
        pausa
        ;;
      2)
        read -p "Usuario a eliminar: " usuario
        userdel -r "$usuario" && echo -e "${rojo}✘ Usuario ${usuario} eliminado.${reset}"
        pausa
        ;;
      3)
        read -p "Usuario a editar: " usuario
        read -s -p "Nueva contraseña: " clave; echo
        echo "$usuario:$clave" | chpasswd && echo -e "${verde}✔ Contraseña actualizada.${reset}"
        pausa
        ;;
      4)
        read -p "Usuario a renovar: " usuario
        read -p "Días adicionales: " dias
        actual=$(chage -l "$usuario" | awk -F': ' '/Account expires/{print $2}')
        if [[ "$actual" == "never" || -z "$actual" ]]; then
          nueva=$(date -d "+$dias days" +%Y-%m-%d)
        else
          nueva=$(date -d "$actual +$dias days" +%Y-%m-%d)
        fi
        chage -E "$nueva" "$usuario"
        echo -e "${verde}✔ Usuario ${usuario} renovado hasta ${nueva}.${reset}"
        pausa
        ;;
      5)
        echo -e "${rojo}➤ Eliminando usuarios caducados...${reset}"
        for u in $(awk -F: '{if ($3 >= 1000 && $1!="nobody") print $1}' /etc/passwd); do
          exp=$(chage -l "$u" | awk -F': ' '/Account expires/{print $2}')
          if [[ "$exp" != "never" && -n "$exp" ]]; then
            if [[ $(date -d "$exp" +%s) -lt $(date +%s) ]]; then
              userdel -r "$u" && echo -e "${rojo}✘ $u eliminado por caducidad.${reset}"
            fi
          fi
        done
        pausa
        ;;
      6)
        echo -e "${cyan}📋 Lista de usuarios SSH:${reset}"
        printf "${amarillo}%-18s %-15s${reset}\n" "Usuario" "Expira"
        echo "-------------------------------------------"
        for u in $(awk -F: '{if ($3 >= 1000 && $1!="nobody") print $1}' /etc/passwd); do
          exp=$(chage -l "$u" | awk -F': ' '/Account expires/{print $2}')
          printf "${verde}%-18s${reset} ${rojo}%-15s${reset}\n" "$u" "${exp:-never}"
        done
        pausa
        ;;
      0) break ;;
      *) echo -e "${rojo}⚠ Opción inválida.${reset}"; pausa ;;
    esac
  done
}

# ======================================
# Submenú: Gestión de Puertos SSL (stunnel)
# ======================================
puertos_menu() {
  while true; do
    clear
    echo -e "${azul}╔══════════════════════════════╗${reset}"
    echo -e "${azul}   ⚙️  Gestión de Puertos SSL    ${reset}"
    echo -e "${azul}╚══════════════════════════════╝${reset}"
    echo -e "${cyan}[1]${reset} ➤ ${cyan}Listar puertos SSL activos${reset}"
    echo -e "${verde}[2]${reset} ➤ ${verde}Agregar puerto SSL${reset}"
    echo -e "${amarillo}[3]${reset} ➤ ${amarillo}Eliminar puerto SSL${reset}"
    echo -e "${violeta}[4]${reset} ➤ ${violeta}Reiniciar Stunnel${reset}"
    echo -e "${rojo}[0]${reset} ⬅ ${rojo}Volver${reset}"
    echo
    read -p "Seleccione una opción: " op
    case "$op" in
      1)
        listar_puertos_ssl
        echo
        ss -tuln | grep -E '(:444|:445|:446|stunnel)' || true
        pausa
        ;;
      2)
        read -p "Puerto SSL a agregar (ej. 447): " port
        if ss -tuln | grep -q ":$port "; then
          echo -e "${rojo}⚠ El puerto $port ya está en uso.${reset}"
        elif grep -q "^\[ssh-$port\]" "$STUNNEL_CONF"; then
          echo -e "${amarillo}⚠ Ya existe la sección ssh-$port en stunnel.${reset}"
        else
          echo -e "\n[ssh-$port]\naccept = $port\nconnect = 22" >> "$STUNNEL_CONF"
          systemctl restart stunnel4 && echo -e "${verde}✔ Agregado y reiniciado.${reset}" || echo -e "${rojo}❌ Falló el reinicio. Revisa logs.${reset}"
        fi
        pausa
        ;;
      3)
        read -p "Puerto SSL a eliminar (ej. 446): " port
        if grep -q "^\[ssh-$port\]" "$STUNNEL_CONF"; then
          # eliminar bloque desde [ssh-port] hasta la siguiente línea en blanco o siguiente sección
          awk -v p="$port" '
            BEGIN{skip=0}
            /^\[ssh-/ {
              if ($0=="[ssh-"p"]") {skip=1; next}
              if (skip==1) {skip=0}
            }
            skip==0 {print}
          ' "$STUNNEL_CONF" > /tmp/stunnel.new && mv /tmp/stunnel.new "$STUNNEL_CONF"
          systemctl restart stunnel4 && echo -e "${verde}✔ Eliminado y reiniciado.${reset}" || echo -e "${rojo}❌ Falló el reinicio. Revisa logs.${reset}"
        else
          echo -e "${amarillo}⚠ No existe ssh-$port en la configuración.${reset}"
        fi
        pausa
        ;;
      4)
        systemctl restart stunnel4 && echo -e "${verde}✔ Stunnel reiniciado.${reset}" || echo -e "${rojo}❌ Error al reiniciar.${reset}"
        pausa
        ;;
      0) break ;;
      *) echo -e "${rojo}⚠ Opción inválida.${reset}"; pausa ;;
    esac
  done
}

# ================================
# Submenú: Estado del sistema
# ================================
sistema_menu() {
  clear
  echo -e "${verde}╔══════════════════════════════╗${reset}"
  echo -e "${verde}     📊 Estado del sistema     ${reset}"
  echo -e "${verde}╚══════════════════════════════╝${reset}"
  echo -e "${cyan}Uptime:${reset}"; uptime
  echo -e "\n${cyan}Memoria:${reset}"; free -h
  echo -e "\n${cyan}Discos:${reset}"; df -h
  echo -e "\n${cyan}Servicios clave:${reset}"
  systemctl --no-pager --plain status ssh stunnel4 2>/dev/null | sed -n '1,6p'
  pausa
}

# ================================
# Submenú: Reinicios y extras
# ================================
extras_menu() {
  while true; do
    clear
    echo -e "${amarillo}╔══════════════════════════════╗${reset}"
    echo -e "${amarillo}   🔄 Reinicios y Utilidades   ${reset}"
    echo -e "${amarillo}╚══════════════════════════════╝${reset}"
    echo -e "${cyan}[1]${reset} ➤ ${cyan}Reiniciar VPS${reset}"
    echo -e "${verde}[2]${reset} ➤ ${verde}Reiniciar SSH + Stunnel${reset}"
    echo -e "${rojo}[0]${reset} ⬅ ${rojo}Volver${reset}"
    echo
    read -p "Seleccione una opción: " op
    case "$op" in
      1) reboot ;;
      2) systemctl restart ssh stunnel4 && echo -e "${verde}✔ Servicios reiniciados.${reset}"; pausa ;;
      0) break ;;
      *) echo -e "${rojo}⚠ Opción inválida.${reset}"; pausa ;;
    esac
  done
}

# ================================
# Menú principal
# ================================
while true; do
  clear
  echo -e "${violeta}╔══════════════════════════════════════════╗${reset}"
  echo -e "${violeta}      🚀   MENÚ ADMINISTRADOR VPS BURGOS   🚀${reset}"
  echo -e "${violeta}╚══════════════════════════════════════════╝${reset}"
  echo -e "${cyan}[1]${reset} 🔑 ${cyan}Gestión de Usuarios${reset}"
  echo -e "${amarillo}[2]${reset} 🔐 ${amarillo}Gestión de Puertos SSL (Stunnel)${reset}"
  echo -e "${verde}[3]${reset} 📊 ${verde}Estado del sistema${reset}"
  echo -e "${rojo}[4]${reset} 🔄 ${rojo}Reinicios y extras${reset}"
  echo -e "${violeta}[0]${reset} ❌ ${violeta}Salir${reset}"
  echo
  read -p "Seleccione una opción: " opcion
  case "$opcion" in
    1) usuarios_menu ;;
    2) puertos_menu ;;
    3) sistema_menu ;;
    4) extras_menu ;;
    0) exit 0 ;;
    *) echo -e "${rojo}⚠ Opción inválida.${reset}"; pausa ;;
  esac
done
EOF

  chmod +x /usr/local/bin/menu_admin.sh

  # accesos globales
  echo "#!/bin/bash
/usr/local/bin/menu_admin.sh" > "$INSTALL_PATH"
  chmod +x "$INSTALL_PATH"
}

autorun_menu() {
  echo "⚙️  Activando auto-ejecución del menú para root..."
  if ! grep -q '^menu$' /root/.bashrc 2>/dev/null; then
    echo "menu" >> /root/.bashrc
  fi
}

# ------------------ MAIN -------------------
need_root
pkg_install
setup_stunnel
setup_motd
install_menu
autorun_menu

echo
echo "✅ Instalación completada."
echo "• Ejecuta: menu"
echo "• Puertos SSL activos (stunnel) → SSH 22: ${DEFAULT_SSL_PORTS[*]}"
echo "• Si stunnel falla: journalctl -u stunnel4 -n 50"