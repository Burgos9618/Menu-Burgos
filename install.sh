#!/bin/bash
# Instalador Burgos Menu
# Autor: Burgos :)

# Ruta donde se instalará el menú
INSTALL_PATH="/usr/local/bin/menu"
SCRIPT_PATH="/usr/local/bin/menu_admin.sh"

# Crear script principal
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
reset="\e[0m"

# Banner compacto
echo -e "${violeta}"
echo "╔══════════════════════╗"
echo "   🚀  MENU BURGOS 🚀  "
echo "╚══════════════════════╝"
echo -e "${reset}"
echo

# Menú
echo -e "${verde}[1]${reset} Crear usuario SSH"
echo -e "${verde}[2]${reset} Eliminar usuario SSH"
echo -e "${verde}[3]${reset} Listar usuarios"
echo -e "${verde}[0]${reset} Salir"
echo

read -p "Seleccione una opción: " opcion

case $opcion in
  1)
    read -p "Nombre de usuario: " usuario
    read -s -p "Contraseña: " clave
    echo
    useradd -m -s /bin/bash "$usuario"
    echo "$usuario:$clave" | chpasswd
    echo -e "${azul}Usuario $usuario creado con éxito.${reset}"
    ;;
  2)
    read -p "Usuario a eliminar: " usuario
    userdel -r "$usuario"
    echo -e "${rojo}Usuario $usuario eliminado.${reset}"
    ;;
  3)
    echo -e "${azul}Usuarios SSH creados:${reset}"
    awk -F: '$3 >= 1000 && $7 == "/bin/bash" {print $1}' /etc/passwd
    ;;
  0)
    echo "Saliendo..."
    exit 0
    ;;
  *)
    echo "Opción no válida."
    ;;
esac
EOF

# Dar permisos de ejecución
chmod +x $SCRIPT_PATH

# Crear alias global "menu"
echo "#!/bin/bash
$SCRIPT_PATH" > $INSTALL_PATH
chmod +x $INSTALL_PATH

# Mensaje de bienvenida al conectarse por SSH
MOTD_FILE="/etc/motd"
cat <<'EOM' > $MOTD_FILE
##############################################
   🚀 Bienvenido al Servidor Burgos 🚀
   Usa el comando: menu
   para administrar usuarios SSH fácilmente
##############################################
EOM

echo "✅ Instalación completada."
echo "Escribe: menu"
