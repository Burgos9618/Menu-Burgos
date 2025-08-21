#!/bin/bash
# Install.sh - VPS Burgos

clear
echo "========================================="
echo "      Instalador VPS - Menu Burgos"
echo "========================================="

# Actualizar sistema
apt update -y && apt upgrade -y

# Instalar dependencias
apt install -y curl wget git net-tools stunnel4 apache2 unzip htop

# Configuración firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 444/tcp
ufw --force enable

# Configuración stunnel
cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no

[ssh]
accept = 443
connect = 127.0.0.1:22
EOF

# Generar certificado
if [ ! -f /etc/stunnel/stunnel.pem ]; then
    openssl req -new -x509 -days 365 -nodes \
    -out /etc/stunnel/stunnel.pem \
    -keyout /etc/stunnel/stunnel.pem \
    -subj "/CN=localhost"
fi

systemctl enable stunnel4
systemctl restart stunnel4

# Crear menú
cat > /usr/local/bin/menu <<'EOM'
#!/bin/bash
while true; do
clear
echo "========================================="
echo "          MENU VPS BURGOS"
echo "========================================="
echo "1) Ver estado del sistema"
echo "2) Ver usuarios activos"
echo "3) Crear usuario SSH"
echo "4) Eliminar usuario SSH"
echo "5) Reiniciar servicios (SSH, Stunnel, Apache)"
echo "6) Reiniciar VPS"
echo "7) Salir"
echo "========================================="
read -p "Seleccione una opción: " opcion

case $opcion in
  1) htop ;;
  2) who ;;
  3) 
     read -p "Usuario: " user
     read -p "Contraseña: " pass
     useradd -m -s /bin/bash $user
     echo "$user:$pass" | chpasswd
     echo "Usuario $user creado con éxito."
     read -p "Presiona Enter para continuar..." ;;
  4)
     read -p "Usuario a eliminar: " userdel
     deluser --remove-home $userdel
     echo "Usuario $userdel eliminado."
     read -p "Presiona Enter para continuar..." ;;
  5)
     systemctl restart ssh
     systemctl restart stunnel4
     systemctl restart apache2
     echo "Servicios reiniciados."
     read -p "Presiona Enter para continuar..." ;;
  6) reboot ;;
  7) exit ;;
  *) echo "Opción inválida"; sleep 1 ;;
esac
done
EOM

chmod +x /usr/local/bin/menu

echo "========================================="
echo " Instalación completada ✅"
echo " Ejecuta el menú con: menu"
echo "========================================="
