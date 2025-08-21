#!/bin/bash
# Instalador Menu Burgos 🚀
# Autor: Burgos

INSTALL_PATH="/usr/local/bin/menu"
SCRIPT_PATH="/usr/local/bin/menu_admin.sh"
MOTD_FILE="/etc/motd"
BANNER_FILE="/etc/ssh/banner"

# Crear script del menú
cat <<'EOF' > $SCRIPT_PATH
#!/bin/bash

# Colores
morado="\e[1;35m"
verde="\e[1;32m"
rojo="\e[1;31m"
azul="\e[1;34m"
cyan="\e[1;36m"
amarillo="\e[1;33m"
reset="\e[0m"

pausa() {
  echo -e "\n${amarillo}Presiona ENTER para continuar...${reset}"
  read
}

usuarios_menu() {
  while true; do
    clear
    echo -e "${morado}╔══════════════════════════════╗${reset}"
    echo -e "${morado}   🔑 Gestión de Usuarios SSH   ${reset}"
    echo -e "${morado}╚══════════════════════════════╝${reset}"
    echo -e "${cyan}[1]${reset} ➤ ${cyan}Crear usuario${reset}"
    echo -e "${amarillo}[2]${reset} ➤ ${amarillo}Eliminar usuario${reset}"
    echo -e "${azul}[3]${reset} ➤ ${azul}Editar usuario${reset}"
    echo -e "${verde}[4]${reset} ➤ ${verde}Renovar usuario${reset}"
    echo -e "${rojo}[5]${reset} ➤ ${rojo}Eliminar usuarios caducados${reset}"
    echo -e "${cyan}[6]${reset} ➤ ${cyan}Lista de usuarios${reset}"
    echo -e "${morado}[0]${reset} ⬅ ${morado}Volver al menú principal${reset}"
    echo
    read -p "Seleccione una opción: " op
    case $op in
      1) read -p "Usuario: " u
         read -s -p "Contraseña: " p; echo
         read -p "Días válidos: " d
         exp=$(date -d "+$d days" +%Y-%m-%d)
         useradd -m -e $exp -s /bin/bash "$u"
         echo "$u:$p" | chpasswd
         echo -e "${verde}✔ Usuario $u creado hasta $exp.${reset}"
         pausa ;;
      2) read -p "Usuario a eliminar: " u
         userdel -r "$u"
         echo -e "${rojo}✘ Usuario $u eliminado.${reset}"
         pausa ;;
      3) read -p "Usuario a editar: " u
         read -s -p "Nueva contraseña: " p; echo
         echo "$u:$p" | chpasswd
         echo -e "${verde}✔ Contraseña de $u actualizada.${reset}"
         pausa ;;
      4) read -p "Usuario a renovar: " u
         read -p "Días adicionales: " d
         new=$(date -d "+$d days" +%Y-%m-%d)
         chage -E $new "$u"
         echo -e "${verde}✔ $u renovado hasta $new.${reset}"
         pausa ;;
      5) echo -e "${rojo}➤ Eliminando usuarios caducados...${reset}"
         for u in $(awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd); do
           exp=$(chage -l "$u" | grep "Account expires" | awk -F": " '{print $2}')
           if [[ $exp != "never" && $(date -d "$exp" +%s) -lt $(date +%s) ]]; then
             userdel -r "$u"
             echo -e "${rojo}✘ $u eliminado por caducidad.${reset}"
           fi
         done
         pausa ;;
      6) echo -e "${cyan}📋 Lista de usuarios SSH:${reset}"
         printf "%-15s %s\n" "Usuario" "Expira"
         echo "--------------------------"
         for u in $(awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd); do
           exp=$(chage -l "$u" | grep "Account expires" | awk -F": " '{print $2}')
           printf "${verde}%-15s${reset} ${rojo}%s${reset}\n" "$u" "$exp"
         done
         pausa ;;
      0) break ;;
      *) echo -e "${rojo}Opción inválida.${reset}"; pausa ;;
    esac
  done
}

puertos_menu() {
  while true; do
    clear
    echo -e "${azul}╔══════════════════════════════╗${reset}"
    echo -e "${azul}   ⚙ Gestión de Puertos VPS   ${reset}"
    echo -e "${azul}╚══════════════════════════════╝${reset}"
    echo -e "${cyan}[1]${reset} ➤ ${cyan}Ver puertos en uso${reset}"
    echo -e "${amarillo}[2]${reset} ➤ ${amarillo}Cambiar puerto SSH${reset}"
    echo -e "${verde}[3]${reset} ➤ ${verde}Configurar Dropbear${reset}"
    echo -e "${morado}[4]${reset} ➤ ${morado}Configurar Stunnel${reset}"
    echo -e "${rojo}[0]${reset} ⬅ ${rojo}Volver al menú principal${reset}"
    echo
    read -p "Seleccione opción: " op
    case $op in
      1) ss -tuln; pausa ;;
      2) read -p "Nuevo puerto SSH: " port
         sed -i "s/^#Port .*/Port $port/" /etc/ssh/sshd_config
         systemctl restart sshd
         echo -e "${verde}✔ SSH puerto cambiado a $port.${reset}"
         pausa ;;
      3) apt-get install -y dropbear
         systemctl enable --now dropbear
         echo -e "${verde}✔ Dropbear instalado.${reset}"
         pausa ;;
      4) apt-get install -y stunnel4
         systemctl enable --now stunnel4
         echo -e "${verde}✔ Stunnel instalado.${reset}"
         pausa ;;
      0) break ;;
      *) echo -e "${rojo}Opción inválida.${reset}"; pausa ;;
    esac
  done
}

sistema_menu() {
  clear
  echo -e "${verde}╔══════════════════════════════╗${reset}"
  echo -e "${verde}     📊 Estado del sistema     ${reset}"
  echo -e "${verde}╚══════════════════════════════╝${reset}"
  uptime; free -h; df -h
  pausa
}

extras_menu() {
  while true; do
    clear
    echo -e "${amarillo}╔══════════════════════════════╗${reset}"
    echo -e "${amarillo}   🔄 Reinicios y Utilidades   ${reset}"
    echo -e "${amarillo}╚══════════════════════════════╝${reset}"
    echo -e "${cyan}[1]${reset} ➤ ${cyan}Reiniciar VPS${reset}"
    echo -e "${verde}[2]${reset} ➤ ${verde}Reiniciar servicios${reset}"
    echo -e "${rojo}[0]${reset} ⬅ ${rojo}Volver al menú principal${reset}"
    echo
    read -p "Seleccione opción: " op
    case $op in
      1) reboot ;;
      2) systemctl restart sshd dropbear stunnel4
         echo -e "${verde}✔ Servicios reiniciados.${reset}"
         pausa ;;
      0) break ;;
      *) echo -e "${rojo}Opción inválida.${reset}"; pausa ;;
    esac
  done
}

while true; do
  clear
  echo -e "${morado}╔══════════════════════════════════════════╗${reset}"
  echo -e "${morado}      🚀 MENÚ ADMINISTRADOR VPS BURGOS 🚀${reset}"
  echo -e "${morado}╚══════════════════════════════════════════╝${reset}"
  echo -e "${cyan}[1]${reset} 🔑 Gestión de Usuarios"
  echo -e "${amarillo}[2]${reset} ⚙ Gestión de Puertos"
  echo -e "${verde}[3]${reset} 📊 Estado del sistema"
  echo -e "${rojo}[4]${reset} 🔄 Reinicios y extras"
  echo -e "${morado}[0]${reset} ❌ Salir"
  read -p "Seleccione: " op
  case $op in
    1) usuarios_menu ;;
    2) puertos_menu ;;
    3) sistema_menu ;;
    4) extras_menu ;;
    0) exit 0 ;;
    *) echo -e "${rojo}Opción inválida.${reset}"; pausa ;;
  esac
done
EOF

chmod +x $SCRIPT_PATH

# Alias global
echo "#!/bin/bash
$SCRIPT_PATH" > $INSTALL_PATH
chmod +x $INSTALL_PATH

# MOTD bienvenida
cat <<'EOL' > $MOTD_FILE
[95m╔══════════════════════════════╗[0m
[95m   🚀  Bienvenido a VPS BURGOS 🚀[0m
[95m╚══════════════════════════════╝[0m
 Soporte: [96m@Escanor_Sama18[0m
EOL

# Banner universal (SSH/Dropbear/Stunnel)
cat <<'EOB' > $BANNER_FILE
========================================================
[95m                 VPS PREMIUM +1 202 956 4661[0m
========================================================

[94mVPS CONFIGURADAS:[0m [97mSSL TUNNEL, SSH,
[94mDROPBEAR, PROXY SQUID, PROXY SOCK, OPEN VPN,
[94mSHADOWSOCK, APACHE2.[0m

[91mPARA COMPRAR CONTACTAME VIA WHATSAPP O
TELEGRAM:[0m [97m+1 202 956 4661[0m [91m@RealStrategy[0m

[92m        🌎 CONECTANDO EL MUNDO AL INTERNET 🌎[0m
========================================================
EOB

# Configure banner for SSH
sed -i 's|#Banner none|Banner /etc/ssh/banner|' /etc/ssh/sshd_config

# Dropbear banner
if [ -f /etc/default/dropbear ]; then
  sed -i 's|DROPBEAR_BANNER=.*|DROPBEAR_BANNER="/etc/ssh/banner"|' /etc/default/dropbear
  grep -q "DROPBEAR_BANNER=" /etc/default/dropbear || echo 'DROPBEAR_BANNER="/etc/ssh/banner"' \
    >> /etc/default/dropbear
fi

# Stunnel banner
if [ -f /etc/stunnel/stunnel.conf ]; then
  grep -q "exec = /bin/cat" /etc/stunnel/stunnel.conf || \
    echo -e "\nexec = /bin/cat\nexecargs = /etc/ssh/banner" \
    >> /etc/stunnel/stunnel.conf
fi

# Restart services
systemctl restart sshd dropbear stunnel4 2>/dev/null

# Auto-run menu on login
grep -qxF "menu" /root/.bashrc || echo "menu" >> /root/.bashrc

echo "✅ Instalación completada. Escribe 'menu' para comenzar."

# Autoejecutar menú al entrar
# ================================
echo "menu" >> /root/.bashrc

echo "✅ Instalación completada. Ejecuta 'menu' para iniciar."
