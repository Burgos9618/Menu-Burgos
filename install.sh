#!/bin/bash
# ============================================
#   🚀 Instalador Burgos VPS Menu Multicolor
#   Autor: Burgos 🚀
# ============================================

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

# 🎨 Colores
violeta="\e[1;35m"
verde="\e[1;32m"
rojo="\e[1;31m"
azul="\e[1;34m"
cyan="\e[1;36m"
amarillo="\e[1;33m"
reset="\e[0m"

# ============================================
# 🖼️ Banner
# ============================================
banner() {
  clear
  echo -e "${violeta}╔════════════════════════════════════════╗${reset}"
  echo -e "${violeta}     🚀  Ningún Sistema es Seguro  🚀     ${reset}"
  echo -e "${violeta}╚════════════════════════════════════════╝${reset}"
  echo
}

# ============================================
# 📌 Menú principal
# ============================================
menu_principal() {
  banner
  echo -e "${cyan}[1]${reset} 👤 Gestionar usuarios SSH"
  echo -e "${amarillo}[2]${reset} 🔧 Herramientas del sistema"
  echo -e "${azul}[3]${reset} ⚙️ Configuración de puertos SSH"
  echo -e "${rojo}[0]${reset} ❌ Salir"
  echo
  read -p "Seleccione una opción: " opcion
  case $opcion in
    1) menu_usuarios ;;
    2) menu_herramientas ;;
    3) menu_puertos ;;
    0) echo -e "${violeta}👋 Saliendo...${reset}"; exit 0 ;;
    *) echo -e "${rojo}⚠ Opción no válida.${reset}"; sleep 1; menu_principal ;;
  esac
}

# ============================================
# 👤 Menú gestión de usuarios
# ============================================
menu_usuarios() {
  banner
  echo -e "${cyan}[1]${reset} ➕ Crear nuevo usuario"
  echo -e "${amarillo}[2]${reset} ➖ Quitar usuario"
  echo -e "${azul}[3]${reset} ✏️ Editar contraseña de usuario"
  echo -e "${verde}[4]${reset} ♻️ Renovar usuario"
  echo -e "${rojo}[5]${reset} 🗑️ Eliminar usuarios caducados"
  echo -e "${violeta}[0]${reset} 🔙 Atrás"
  echo
  read -p "Seleccione una opción: " opcion
  case $opcion in
    1)
      read -p "Nombre de usuario: " usuario
      read -s -p "Contraseña: " clave; echo
      read -p "Días de validez: " dias
      useradd -m -s /bin/bash -e $(date -d "+$dias days" +%Y-%m-%d) "$usuario"
      echo "$usuario:$clave" | chpasswd
      echo -e "${verde}✔ Usuario $usuario creado con éxito. Expira en $dias días.${reset}"
      ;;
    2)
      read -p "Usuario a eliminar: " usuario
      userdel -r "$usuario"
      echo -e "${rojo}✘ Usuario $usuario eliminado.${reset}"
      ;;
    3)
      read -p "Usuario a editar: " usuario
      read -s -p "Nueva contraseña: " clave; echo
      echo "$usuario:$clave" | chpasswd
      echo -e "${azul}✔ Contraseña de $usuario cambiada.${reset}"
      ;;
    4)
      read -p "Usuario a renovar: " usuario
      read -p "Días adicionales: " dias
      chage -E $(date -d "+$dias days" +%Y-%m-%d) "$usuario"
      echo -e "${verde}♻️ Usuario $usuario renovado por $dias días.${reset}"
      ;;
    5)
      echo -e "${rojo}🗑️ Eliminando usuarios caducados...${reset}"
      for u in $(cut -d: -f1 /etc/passwd); do
        exp=$(chage -l $u | grep "Account expires" | cut -d: -f2)
        if [[ "$exp" != " never" && "$exp" != "" ]]; then
          fecha=$(date -d "$exp" +%s 2>/dev/null)
          hoy=$(date +%s)
          if [[ $fecha -lt $hoy ]]; then
            userdel -r "$u"
            echo "Eliminado: $u"
          fi
        fi
      done
      echo -e "${verde}✔ Usuarios caducados eliminados.${reset}"
      ;;
    0) menu_principal ;;
    *) echo -e "${rojo}⚠ Opción no válida.${reset}"; sleep 1; menu_usuarios ;;
  esac
  read -p "Presione Enter para continuar..." enter
  menu_usuarios
}

# ============================================
# 🔧 Menú herramientas del sistema
# ============================================
menu_herramientas() {
  banner
  echo -e "${cyan}[1]${reset} 🔄 Reiniciar VPS"
  echo -e "${amarillo}[2]${reset} 📊 Estado del sistema"
  echo -e "${violeta}[0]${reset} 🔙 Atrás"
  echo
  read -p "Seleccione una opción: " opcion
  case $opcion in
    1) echo -e "${rojo}Reiniciando VPS...${reset}"; reboot ;;
    2)
      echo -e "${verde}➤ Estado del sistema:${reset}"
      uptime
      free -h
      df -h
      ;;
    0) menu_principal ;;
    *) echo -e "${rojo}⚠ Opción no válida.${reset}"; sleep 1; menu_herramientas ;;
  esac
  read -p "Presione Enter para continuar..." enter
  menu_herramientas
}

# ============================================
# ⚙️ Menú configuración de puertos SSH
# ============================================
menu_puertos() {
  banner
  echo -e "${cyan}[1]${reset} ➕ Agregar puerto SSH"
  echo -e "${amarillo}[2]${reset} ➖ Quitar puerto SSH"
  echo -e "${verde}[3]${reset} 📋 Listar puertos activos"
  echo -e "${violeta}[0]${reset} 🔙 Atrás"
  echo
  read -p "Seleccione una opción: " opcion
  case $opcion in
    1)
      read -p "Ingrese el puerto a agregar: " puerto
      echo "Port $puerto" >> /etc/ssh/sshd_config
      systemctl restart sshd
      echo -e "${verde}✔ Puerto $puerto agregado y SSH reiniciado.${reset}"
      ;;
    2)
      read -p "Ingrese el puerto a eliminar: " puerto
      sed -i "/Port $puerto/d" /etc/ssh/sshd_config
      systemctl restart sshd
      echo -e "${rojo}✘ Puerto $puerto eliminado y SSH reiniciado.${reset}"
      ;;
    3)
      echo -e "${verde}📋 Puertos activos:${reset}"
      grep "^Port" /etc/ssh/sshd_config
      ;;
    0) menu_principal ;;
    *) echo -e "${rojo}⚠ Opción no válida.${reset}"; sleep 1; menu_puertos ;;
  esac
  read -p "Presione Enter para continuar..." enter
  menu_puertos
}

# ============================================
# 🚀 Iniciar menú principal
# ============================================
menu_principal
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
# Ejecutar menú al iniciar sesión
# ================================
if ! grep -q "menu" /root/.bashrc; then
  echo "menu" >> /root/.bashrc
fi

echo "✅ Instalación completada. Escribe 'menu' para abrir el panel."
