#!/bin/bash
# Instalador Burgos Menu Full Color
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

# 🎨 Colores
violeta="\e[1;35m"
verde="\e[1;32m"
rojo="\e[1;31m"
azul="\e[1;34m"
amarillo="\e[1;33m"
cyan="\e[1;36m"
neon="\e[95m"
reset="\e[0m"

# 🚀 Banner colorido
echo -e "${violeta}"
echo "╔══════════════════════════════╗"
echo "      🚀  ${neon}MENU BURGOS${violeta} 🚀"
echo "╚══════════════════════════════╝"
echo -e "${reset}"
echo

# 🎨 Menú principal
echo -e "${amarillo}[1] 👤 Crear usuario SSH${reset}"
echo -e "${rojo}[2] 🗑️  Eliminar usuario SSH${reset}"
echo -e "${cyan}[3] 📋 Listar usuarios${reset}"
echo -e "${violeta}[0] 🚪 Salir${reset}"
echo

# 📝 Pregunta principal
echo -ne "${verde}Seleccione una opción:${reset} "
read opcion

case $opcion in
  1)
    echo -ne "${amarillo}👤 Nombre de usuario:${reset} "
    read usuario
    echo -ne "${violeta}🔑 Contraseña:${reset} "
    read -s clave
    echo
    if id "$usuario" &>/dev/null; then
      echo -e "${rojo}⚠️  El usuario $usuario ya existe.${reset}"
    else
      useradd -m -s /bin/bash "$usuario"
      echo "$usuario:$clave" | chpasswd
      echo -e "${azul}✅ Usuario $usuario creado con éxito.${reset}"
    fi
    ;;
  2)
    echo -ne "${amarillo}🗑️ Usuario a eliminar:${reset} "
    read usuario
    if id "$usuario" &>/dev/null; then
      userdel -r "$usuario"
      echo -e "${rojo}❌ Usuario $usuario eliminado.${reset}"
    else
      echo -e "${rojo}⚠️  El usuario $usuario no existe.${reset}"
    fi
    ;;
  3)
    echo -e "${cyan}📋 Usuarios SSH creados:${reset}"
    awk -F: '$3 >= 1000 && $7 == "/bin/bash" {print " - " $1}' /etc/passwd
    ;;
  0)
    echo -e "${violeta}👋 Cerrando el menú...${reset}"
    exit 0
    ;;
  *)
    echo -e "${rojo}⚠️  Opción no válida.${reset}"
    ;;
esac
EOF

# Dar permisos de ejecución
chmod +x $SCRIPT_PATH

# Crear alias global "menu"
echo "#!/bin/bash
$SCRIPT_PATH" > $INSTALL_PATH
chmod +x $INSTALL_PATH

# 🖼️ Mensaje de bienvenida al conectar por SSH
MOTD_FILE="/etc/motd"
cat <<'EOM' > $MOTD_FILE
=============================================
🚀 Bienvenido al Servidor Burgos 🚀

👉 Usa el comando: menu
   para administrar usuarios SSH fácilmente
=============================================
EOM

echo "✅ Instalación completada."
echo "Escribe: menu"
