#!/bin/bash
# ======================================================
# Instalador VPS Burgos
# Configura: SSH, Stunnel (SSL), Firewall y Menú
# ======================================================

INSTALL_PATH="/usr/local/bin/menu"
SCRIPT_PATH="/usr/local/bin/menu_admin.sh"
MOTD_FILE="/etc/motd"
DEFAULT_SSL_PORTS=("443" "445" "446")

echo "============================================"
echo " 🚀 Instalador VPS Burgos"
echo "============================================"

# 1. Actualizar sistema e instalar dependencias
apt-get update -y && apt-get upgrade -y
apt-get install -y dropbear stunnel4 net-tools ufw curl git gawk screen

# 2. Configurar SSH (22 como default y 444 adicional)
echo "➤ Configurando SSH..."
grep -q "^Port 22" /etc/ssh/sshd_config || echo "Port 22" >> /etc/ssh/sshd_config
grep -q "^Port 444" /etc/ssh/sshd_config || echo "Port 444" >> /etc/ssh/sshd_config
systemctl restart ssh

# 3. Configurar Stunnel (SSL→SSH)
echo "➤ Configurando Stunnel..."
mkdir -p /etc/stunnel

# Generar certificado si no existe
if [ ! -f /etc/stunnel/stunnel.pem ]; then
  openssl req -new -x509 -days 365 -nodes \
    -subj "/CN=burgos-vps" \
    -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem
  chmod 600 /etc/stunnel/stunnel.pem
fi

# Crear stunnel.conf
cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
foreground = no
client = no
setuid = stunnel4
setgid = stunnel4
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
EOF

# Agregar servicios SSL
for port in "${DEFAULT_SSL_PORTS[@]}"; do
  cat >> /etc/stunnel/stunnel.conf <<EOF

[ssh-$port]
accept = $port
connect = 22
EOF
done

# Habilitar stunnel4
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
systemctl enable stunnel4 >/dev/null 2>&1
systemctl restart stunnel4

# 4. Configurar firewall
echo "➤ Configurando firewall (UFW)..."
ufw allow 22/tcp
ufw allow 444/tcp
ufw allow 443/tcp
ufw allow 445/tcp
ufw allow 446/tcp
ufw --force enable

# 5. MOTD personalizado
cat > "$MOTD_FILE" <<'EOM'
============================================
 ⚡ VPS Burgos instalado con éxito
 Usa "menu" para administrar tu servidor
============================================
EOM

# 6. Crear menú administrador
cat > "$SCRIPT_PATH" <<'EOF'
#!/bin/bash

# Colores
verde="\e[1;32m"; rojo="\e[1;31m"; cyan="\e[1;36m"; reset="\e[0m"

clear
echo "===== MENÚ ADMINISTRACIÓN VPS ====="
echo "1) Crear usuario SSH"
echo "2) Eliminar usuario SSH"
echo "3) Listar usuarios SSH"
echo "4) Mostrar conexiones activas"
echo "0) Salir"
echo "===================================="
read -p "Opción: " op

case "$op" in
  1)
    read -p "Usuario: " u
    read -p "Contraseña: " p
    read -p "Expira en (días): " d
    exp=$(date -d "+$d days" +%Y-%m-%d)
    useradd -e "$exp" -M -s /bin/false "$u"
    echo "$u:$p" | chpasswd
    echo -e "${verde}Usuario $u creado (expira $exp)${reset}"
    ;;
  2)
    read -p "Usuario a eliminar: " u
    userdel -r "$u"
    echo -e "${rojo}Usuario $u eliminado${reset}"
    ;;
  3)
    echo "Usuarios SSH:"
    awk -F: '$3>=1000{print $1}' /etc/passwd
    ;;
  4)
    echo "Conexiones activas:"
    netstat -tnpa | grep 'ESTABLISHED.*sshd'
    ;;
  0) exit ;;
  *) echo "Opción inválida" ;;
esac
EOF

chmod +x "$SCRIPT_PATH"
ln -sf "$SCRIPT_PATH" "$INSTALL_PATH"

# 7. Autoejecutar el menú al iniciar sesión root
grep -qxF "$INSTALL_PATH" /root/.bashrc || echo "$INSTALL_PATH" >> /root/.bashrc

echo "============================================"
echo " ✅ Instalación completada"
echo " Ejecuta el menú con: menu"
echo " Puertos SSH: 22, 444"
echo " Puertos SSL: 443, 445, 446"
echo "============================================"
