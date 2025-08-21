#!/bin/bash
# Instalador Burgos Menu actualizado
# Autor: Burgos 🚀

INSTALL_PATH="/usr/local/bin/menu"
SCRIPT_PATH="/usr/local/bin/menu_admin.sh"
MOTD_FILE="/etc/motd"

# ================================
# Crear script principal (menu)
# ================================
cat <<'EOF' > $SCRIPT_PATH
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

while true; do
  clear
  # Banner
  echo -e "${violeta}╔══════════════════════════════════════════╗${reset}"
  echo -e "${violeta}      🚀  Ningun Sistema Es Seguro 🚀       ${reset}"
  echo -e "${violeta}╚══════════════════════════════════════════╝${reset}"
  echo

  # Menú con colores
  echo -e "${cyan}[1]${reset} Crear usuario SSH"
  echo -e "${amarillo}[2]${reset} Eliminar usuario SSH"
  echo -e "${azul}[3]${reset} Listar usuarios"
  echo -e "${rojo}[4]${reset} Reiniciar VPS"
  echo -e "${verde}[5]${reset} Estado del sistema"
  echo -e "${violeta}[0]${reset} Salir"
  echo

  # Pregunta colorida
  echo -ne "${amarillo}👉 Seleccione una opción:${reset} "
  read opcion

  case $opcion in
    1)
      clear
      echo -e "${cyan}➤ Creando usuario...${reset}"
      echo -ne "${cyan}Nombre de usuario:${reset} "
      read usuario
      echo -ne "${cyan}Contraseña:${reset} "
      read -s clave
      echo
      useradd -m -s /bin/bash "$usuario" &>/dev/null
      echo "$usuario:$clave" | chpasswd
      echo -e "${verde}✔ Usuario $usuario creado con éxito.${reset}"
      echo -e "${violeta}[0] Atrás${reset}"
      read -p "Presione Enter para continuar..."
      ;;
    2)
      clear
      echo -e "${amarillo}➤ Eliminando usuario...${reset}"
      echo -ne "${cyan}Usuario a eliminar:${reset} "
      read usuario
      userdel -r "$usuario" &>/dev/null
      if [ $? -eq 0 ]; then
        echo -e "${rojo}✘ Usuario $usuario eliminado.${reset}"
      else
        echo -e "${amarillo}⚠ El usuario no existe.${reset}"
      fi
      echo -e "${violeta}[0] Atrás${reset}"
      read -p "Presione Enter para continuar..."
      ;;
    3)
      clear
      echo -e "${azul}➤ Usuarios SSH existentes:${reset}"
      getent passwd {1000..60000} | cut -d: -f1
      echo
      echo -e "${violeta}[0] Atrás${reset}"
      read -p "Presione Enter para continuar..."
      ;;
    4)
      clear
      echo -e "${rojo}Reiniciando VPS...${reset}"
      reboot
      ;;
    5)
      clear
      echo -e "${verde}➤ Estado del sistema:${reset}"
      uptime
      free -h
      df -h
      echo
      echo -e "${violeta}[0] Atrás${reset}"
      read -p "Presione Enter para continuar..."
      ;;
    0)
      echo -e "${violeta}👋 Saliendo del menú...${reset}"
      exit 0
      ;;
    *)
      echo -e "${rojo}⚠ Opción no válida.${reset}"
      sleep 2
      ;;
  esac
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

echo "✅ Instalación completada."
