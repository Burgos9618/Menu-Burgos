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
echo -e "${cyan}[1] Crear usuario SSH${reset}"
echo -e "${amarillo}[2] Eliminar usuario SSH${reset}"
echo -e "${azul}[3] Lista de usuarios SSH${reset}"
echo -e "${rojo}[4] Reiniciar VPS${reset}"
echo -e "${verde}[5] Estado del sistema${reset}"
echo -e "${violeta}[0] Salir${reset}"
echo

read -p "Seleccione una opción: " opcion

case $opcion in
  1)
    echo -e "${cyan}➤ Creando usuario...${reset}"
    read -p "Nombre de usuario: " usuario
    read -s -p "Contraseña: " clave
    echo
    read -p "Días de validez: " dias
    useradd -m -s /bin/bash -e $(date -d "+$dias days" +"%Y-%m-%d") "$usuario"
    echo "$usuario:$clave" | chpasswd
    echo -e "${verde}✔ Usuario $usuario creado con éxito. Expira en $dias días.${reset}"
    ;;
  2)
    echo -e "${amarillo}➤ Eliminando usuario...${reset}"
    read -p "Usuario a eliminar: " usuario
    userdel -r "$usuario"
    echo -e "${rojo}✘ Usuario $usuario eliminado.${reset}"
    ;;
  3)
    echo -e "${azul}➤ Lista de usuarios SSH:${reset}"
    awk -F: '$3>=1000 && $1!="nobody"{print $1}' /etc/passwd
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

# ================================
# Mensaje final
# ================================
echo -e "\e[1;32m✅ Instalación completada con éxito.\e[0m"
echo -e "\e[1;36mPara volver a instalar o actualizar usa:\e[0m"
echo -e "\e[1;35mbash <(curl -s https://raw.githubusercontent.com/Burgos9618/Menu-Burgos/main/install.sh)\e[0m"
