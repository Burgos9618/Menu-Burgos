#!/bin/bash
# Instalador Menu Burgos 🚀
# Autor: Burgos

INSTALL_PATH="/usr/local/bin/menu"
SCRIPT_PATH="/usr/local/bin/menu_admin.sh"
MOTD_FILE="/etc/motd"

# ================================
# Crear script principal (menu)
# ================================
cat <<'EOF' > $SCRIPT_PATH
#!/bin/bash

# 🎨 Colores
violeta="\e[1;35m"
verde="\e[1;32m"
rojo="\e[1;31m"
azul="\e[1;34m"
cyan="\e[1;36m"
amarillo="\e[1;33m"
reset="\e[0m"

# Función para pausar
pausa() {
  echo -e "\n${amarillo}Presiona ENTER para continuar...${reset}"
  read
}

# ================================
# Submenú: Gestión de Usuarios SSH
# ================================
usuarios_menu() {
  while true; do
    clear
    echo -e "${violeta}╔══════════════════════════════╗${reset}"
    echo -e "${violeta}   🔑 Gestión de Usuarios SSH   ${reset}"
    echo -e "${violeta}╚══════════════════════════════╝${reset}"
    echo -e "${cyan}[1]${reset} ➤ ${cyan}Crear usuario${reset}"
    echo -e "${amarillo}[2]${reset} ➤ ${amarillo}Eliminar usuario${reset}"
    echo -e "${azul}[3]${reset} ➤ ${azul}Editar usuario${reset}"
    echo -e "${verde}[4]${reset} ➤ ${verde}Renovar usuario${reset}"
    echo -e "${rojo}[5]${reset} ➤ ${rojo}Eliminar usuarios caducados${reset}"
    echo -e "${violeta}[0]${reset} ⬅ $¨{violeta}Volver al menú principal${reset}"
    echo
    read -p "Seleccione una opción: " op
    case $op in
      1) echo -e "${cyan}➤ Creando usuario...${reset}"
         read -p "Usuario: " usuario
         read -s -p "Contraseña: " clave
         echo; read -p "Días válidos: " dias
         expira=$(date -d "+$dias days" +%Y-%m-%d)
         useradd -m -e $expira -s /bin/bash $usuario
         echo "$usuario:$clave" | chpasswd
         echo -e "${verde}✔ Usuario $usuario creado hasta $expira.${reset}"
         pausa ;;
      2) read -p "Usuario a eliminar: " usuario
         userdel -r $usuario
         echo -e "${rojo}✘ Usuario $usuario eliminado.${reset}"
         pausa ;;
      3) read -p "Usuario a editar: " usuario
         read -s -p "Nueva contraseña: " clave
         echo; echo "$usuario:$clave" | chpasswd
         echo -e "${verde}✔ Contraseña de $usuario actualizada.${reset}"
         pausa ;;
      4) read -p "Usuario a renovar: " usuario
         read -p "Días adicionales: " dias
         chage -E $(date -d "+$dias days" +%Y-%m-%d) $usuario
         echo -e "${verde}✔ Usuario $usuario renovado.${reset}"
         pausa ;;
      5) echo -e "${rojo}➤ Eliminando usuarios caducados...${reset}"
         for u in $(awk -F: '{print $1}' /etc/passwd); do
           exp=$(chage -l $u | grep "Account expires" | awk -F": " '{print $2}')
           if [[ $exp != "never" && $(date -d "$exp" +%s) -lt $(date +%s) ]]; then
             userdel -r $u
             echo -e "${rojo}✘ $u eliminado por caducidad.${reset}"
           fi
         done
         pausa ;;
      0) break ;;
      *) echo -e "${rojo}⚠ Opción inválida.${reset}"; pausa ;;
    esac
  done
}

# ================================
# Submenú: Gestión de Puertos
# ================================
puertos_menu() {
  while true; do
    clear
    echo -e "${azul}╔══════════════════════════════╗${reset}"
    echo -e "${azul}   ⚙️  Gestión de Puertos VPS   ${reset}"
    echo -e "${azul}╚══════════════════════════════╝${reset}"
    echo -e "${cyan}[1] ➤ Ver puertos en uso${reset}"
    echo -e "${amarillo}[2] ➤ Cambiar puerto SSH${reset}"
    echo -e "${verde}[3] ➤ Configurar Dropbear${reset}"
    echo -e "${violeta}[4] ➤ Configurar Stunnel${reset}"
    echo -e "${rojo}[0] ⬅ Volver al menú principal${reset}"
    echo
    read -p "Seleccione una opción: " op
    case $op in
      1) ss -tuln
         pausa ;;
      2) read -p "Nuevo puerto SSH: " port
         sed -i "s/^#Port .*/Port $port/" /etc/ssh/sshd_config
         systemctl restart sshd
         echo -e "${verde}✔ Puerto SSH cambiado a $port.${reset}"
         pausa ;;
      3) echo -e "${amarillo}➤ Configuración básica Dropbear...${reset}"
         apt-get install -y dropbear
         systemctl enable dropbear
         systemctl restart dropbear
         echo -e "${verde}✔ Dropbear instalado y corriendo.${reset}"
         pausa ;;
      4) echo -e "${violeta}➤ Configuración básica Stunnel...${reset}"
         apt-get install -y stunnel4
         systemctl enable stunnel4
         echo -e "${verde}✔ Stunnel instalado.${reset}"
         pausa ;;
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
  uptime
  free -h
  df -h
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
    echo -e "${cyan}[1]${reset} ➤ Reiniciar VPS"
    echo -e "${verde}[2]${reset} ➤ Reiniciar servicios"
    echo -e "${rojo}[0]${reset} ⬅ Volver al menú principal"
    echo
    read -p "Seleccione una opción: " op
    case $op in
      1) reboot ;;
      2) systemctl restart sshd dropbear stunnel4
         echo -e "${verde}✔ Servicios reiniciados.${reset}"
         pausa ;;
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
  echo -e "${amarillo}[2]${reset} ⚙️  ${amarillo}Gestión de Puertos${reset}"
  echo -e "${verde}[3]${reset} 📊 ${verde}Estado del sistema${reset}"
  echo -e "${rojo}[4]${reset} 🔄 ${rojo}Reinicios y extras${reset}"
  echo -e "${violeta}[0]${reset} ❌ ${violeta}Salir${reset}"
  echo
  read -p "Seleccione una opción: " opcion
  case $opcion in
    1) usuarios_menu ;;
    2) puertos_menu ;;
    3) sistema_menu ;;
    4) extras_menu ;;
    0) exit 0 ;;
    *) echo -e "${rojo}⚠ Opción inválida.${reset}"; pausa ;;
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
# Configurar mensaje MOTD
# ================================
cat <<'EOM' > $MOTD_FILE
[95m╔══════════════════════════════╗[0m
[95m   🚀  Bienvenido a VPS BURGOS 🚀[0m
[95m╚══════════════════════════════╝[0m
 Soporte: [96m@Escanor_Sama18[0m
EOM

# ================================
# Autoejecutar menú al entrar
# ================================
echo "menu" >> /root/.bashrc

echo "✅ Instalación completada. Ejecuta 'menu' para iniciar."
