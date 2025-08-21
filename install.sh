#!/bin/bash
# Instalador Burgos Menu actualizado
# Autor: Burgos & ChatGPT 🚀

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
    read -p "Nombre de usuario: " usuario

