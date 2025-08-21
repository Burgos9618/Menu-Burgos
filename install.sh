#!/bin/bash
# ============================================
# 🚀 Instalador MENU BURGOS VPS (One-File)
# ============================================

# 📌 Rutas
SCRIPT_PATH="/usr/local/bin/menu_admin.sh"
INSTALL_PATH="/usr/bin/menu"
MOTD_FILE="/etc/motd"

# ================================
# Instalar dependencias necesarias
# ================================
echo "🔄 Instalando dependencias necesarias..."
apt-get update -y
apt-get install -y curl wget unzip net-tools ufw stunnel4

# ================================
# Crear script principal (menu_admin.sh)
# ================================
cat <<'EOF' > $SCRIPT_PATH
#!/bin/bash
# ==============================
#   🚀 MENU BURGOS VPS
# ==============================

# 🎨 Colores
violeta="\e[1;35m"
verde="\e[1;32m"
rojo="\e[1;31m"
azul="\e[1;34m"
cyan="\e[1;36m"
amarillo="\e[1;33m"
reset="\e[0m"

# ==============================
# 📌 FUNCIONES
# ==============================

crear_usuario() {
  echo -e "${cyan}➤ Crear nuevo usuario SSH${reset}"
  read -p "👤 Nombre de usuario: " usuario
  read -s -p "🔑 Contraseña: " clave; echo
  read -p "📅 Días de validez: " dias
  useradd -m -s /bin/bash -e $(date -d "+$dias days" +"%Y-%m-%d") "$usuario"
  echo "$usuario:$clave" | chpasswd
  echo -e "${verde}✔ Usuario $usuario creado con validez de $dias días.${reset}"
}

eliminar_usuario() {
  echo -e "${amarillo}➤ Eliminar usuario SSH${reset}"
  read -p "👤 Usuario a eliminar: " usuario
  userdel -r "$usuario" && echo -e "${rojo}✘ Usuario $usuario eliminado.${reset}"
}

editar_usuario() {
  echo -e "${violeta}➤ Editar usuario SSH${reset}"
  read -p "👤 Usuario a editar: " usuario
  read -s -p "🔑 Nueva contraseña: " clave; echo
  echo "$usuario:$clave" | chpasswd
  echo -e "${verde}✔ Contraseña de $usuario actualizada.${reset}"
}

renovar_usuario() {
  echo -e "${azul}➤ Renovar usuario SSH${reset}"
  read -p "👤 Usuario a renovar: " usuario
  read -p "📅 Días adicionales: " dias
  chage -E $(date -d "+$dias days" +"%Y-%m-%d") "$usuario"
  echo -e "${verde}✔ Usuario $usuario renovado por $dias días.${reset}"
}

eliminar_caducados() {
  echo -e "${rojo}➤ Eliminando usuarios caducados...${reset}"
  for u in $(awk -F: '{print $1}' /etc/passwd); do
    exp=$(chage -l $u 2>/dev/null | grep "Account expires" | cut -d: -f2)
    if [[ "$exp" != " never" && "$exp" != "" ]]; then
      exp_date=$(date -d "$exp" +%s)
      now=$(date +%s)
      if (( exp_date < now )); then
        userdel -r "$u"
        echo -e "${rojo}✘ Usuario $u eliminado (caducado).${reset}"
      fi
    fi
  done
}

listar_usuarios() {
  echo -e "${amarillo}👥 Lista de usuarios activos:${reset}"
  awk -F: '$3>=1000 {print $1}' /etc/passwd
}

estado_sistema() {
  echo -e "${verde}🖥 Estado del sistema:${reset}"
  uptime
  free -h
  df -h
}

configurar_puertos() {
  echo -e "${cyan}⚙ Gestión de puertos SSH${reset}"
  read -p "➤ Puerto nuevo SSH: " puerto
  sed -i "s/^#Port 22/Port $puerto/; s/^Port [0-9]*/Port $puerto/" /etc/ssh/sshd_config
  systemctl restart ssh
  echo -e "${verde}✔ Puerto SSH cambiado a $puerto${reset}"
}

configurar_stunnel() {
  echo -e "${violeta}🔐 Configuración de Stunnel4${reset}"
  read -p "➤ Puerto local (ej. 443): " puerto
  read -p "➤ Redirigir a (ej. 22): " destino
  cat > /etc/stunnel/stunnel.conf <<-ST
pid = /stunnel.pid
[stunnel]
accept = $puerto
connect = 127.0.0.1:$destino
ST
  systemctl restart stunnel4
  echo -e "${verde}✔ Stunnel configurado en el puerto $puerto -> $destino${reset}"
}

# ==============================
# 📌 MENU PRINCIPAL
# ==============================
while true; do
  clear
  echo -e "${violeta}╔══════════════════════════════════════════╗${reset}"
  echo -e "${violeta}      🚀  MENU BURGOS VPS 🚀               ${reset}"
  echo -e "${violeta}╚══════════════════════════════════════════╝${reset}"
  echo
  echo -e "${cyan}[1]${reset} 👤 Crear usuario SSH"
  echo -e "${amarillo}[2]${reset} ❌ Eliminar usuario SSH"
  echo -e "${violeta}[3]${reset} ✏ Editar usuario SSH"
  echo -e "${azul}[4]${reset} 🔄 Renovar usuario SSH"
  echo -e "${rojo}[5]${reset} 🗑 Eliminar usuarios caducados"
  echo -e "${verde}[6]${reset} 📋 Listar usuarios"
  echo -e "${cyan}[7]${reset} ⚙ Cambiar puerto SSH"
  echo -e "${violeta}[8]${reset} 🔐 Configurar Stunnel4"
  echo -e "${azul}[9]${reset} 🖥 Estado del sistema"
  echo -e "${rojo}[0]${reset} 🚪 Salir"
  echo
  read -p "👉 Seleccione una opción: " opcion
  case $opcion in
    1) crear_usuario ;;
    2) eliminar_usuario ;;
    3) editar_usuario ;;
    4) renovar_usuario ;;
    5) eliminar_caducados ;;
    6) listar_usuarios ;;
    7) configurar_puertos ;;
    8) configurar_stunnel ;;
    9) estado_sistema ;;
    0) echo -e "${rojo}👋 Saliendo...${reset}"; exit 0 ;;
    *) echo -e "${rojo}⚠ Opción inválida${reset}" ;;
  esac
  echo; read -p "Presiona ENTER para volver al menú..."
done
EOF

chmod +x $SCRIPT_PATH

# ================================
# Crear acceso global "menu"
# ================================
echo "#!/bin/bash
$SCRIPT_PATH" > $INSTALL_PATH
chmod +x $INSTALL_PATH

# ================================
# Configurar mensaje de bienvenida MOTD
# ================================
cat <<'EOM' > $MOTD_FILE
[95m╔══════════════════════════════╗[0m
[95m   🚀  Bienvenido a VPS BURGOS 🚀[0m
[95m╚══════════════════════════════╝[0m
 Soporte: [96m@Escanor_Sama18[0m
EOM

# ================================
# Hacer que el menú se ejecute al entrar
# ================================
if ! grep -q "menu" /root/.bashrc; then
  echo "menu" >> /root/.bashrc
fi

echo "✅ Instalación completada. Usa el comando: menu"
