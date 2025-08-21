
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

# Banner
echo -e "${violeta}╔══════════════════════════════════════════╗${reset}"
echo -e "${violeta}      🚀  Ningun Sistema Es Seguro 🚀       ${reset}"
echo -e "${violeta}╚══════════════════════════════════════════╝${reset}"
echo

# Menú con colores diferentes
echo -e "${cyan}[1]${reset} Crear usuario SSH"
echo -e "${amarillo}[2]${reset} Eliminar usuario SSH"
echo -e "${azul}[3]${reset} Listar usuarios"
echo -e "${rojo}[4]${reset} Reiniciar VPS"
echo -e "${verde}[5]${reset} Estado del sistema"
echo -e "${violeta}[0]${reset} Salir"
echo

read -p "Seleccione una opción: " opcion

case $opcion in
  1)
    echo -e "${cyan}➤ Creando usuario...${reset}"
    read -p "$(echo -e ${amarillo}Nombre de usuario:${reset} ) " usuario
    read -s -p "$(echo -e ${verde}Contraseña:${reset} ) " clave
    echo
    useradd -m -s /bin/bash "$usuario"
    echo "$usuario:$clave" | chpasswd
    echo "$usuario" >> /etc/burgos_users.txt
    echo -e "${verde}✔ Usuario $usuario creado con éxito.${reset}"
    ;;
  2)
    echo -e "${amarillo}➤ Eliminando usuario...${reset}"
    read -p "$(echo -e ${rojo}Usuario a eliminar:${reset} ) " usuario
    userdel -r "$usuario"
    sed -i "/^$usuario$/d" /etc/burgos_users.txt
    echo -e "${rojo}✘ Usuario $usuario eliminado.${reset}"
    ;;
  3)
    echo -e "${azul}➤ Usuarios creados con el menú:${reset}"
    if [[ -f /etc/burgos_users.txt ]]; then
      cat /etc/burgos_users.txt
    else
      echo -e "${rojo}No hay usuarios registrados.${reset}"
    fi
    ;;
  4)
    echo -e "${rojo}Reiniciando VPS...${reset}"
    reboot
    ;;
  5)
    echo -e "${verde}➤ Estado del sistema:${reset}"
    uptime
    free -h
    df -h
    ;;
  0)
    echo -e "${violeta}👋 Saliendo del menú...${reset}"
    exit 0
    ;;
  *)
    echo -e "${rojo}⚠ Opción no válida.${reset}"
    ;;
esac
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
