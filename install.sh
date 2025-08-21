#!/bin/bash
# ==============================================
#   Install.sh - Instalador VPS Burgos 🚀
#   Configura: SSH, SSL (stunnel), UFW y el menú
# ==============================================

INSTALL_PATH="/usr/local/bin/menu"
SCRIPT_PATH="/usr/local/bin/menu_admin.sh"
MOTD_FILE="/etc/motd"

echo "============================================"
echo " 🚀 Instalador VPS Burgos"
echo "============================================"

# ----------------------------------------------
# 1. Actualizar sistema e instalar dependencias
# ----------------------------------------------
apt-get update -y && apt-get upgrade -y
apt-get install -y dropbear stunnel4 net-tools ufw curl git

# ----------------------------------------------
# 2. Configurar SSH (22 y 444)
# ----------------------------------------------
echo "➤ Configurando SSH..."
sed -i '/^Port /d' /etc/ssh/sshd_config
echo "Port 22" >> /etc/ssh/sshd_config
echo "Port 444" >> /etc/ssh/sshd_config
systemctl restart sshd

# ----------------------------------------------
# 3. Configurar Stunnel (443 → 22)
# ----------------------------------------------
echo "➤ Configurando Stunnel..."
cat > /etc/stunnel/stunnel.conf <<EOF
client = no
[ssh]
accept = 443
connect = 22
cert = /etc/stunnel/stunnel.pem
EOF

# Crear certificado autofirmado
openssl req -new -x509 -days 365 -nodes -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem -subj "/CN=VPSBurgos"
chmod 600 /etc/stunnel/stunnel.pem

# Activar stunnel
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
systemctl restart stunnel4

# ----------------------------------------------
# 4. Configurar Firewall (UFW)
# ----------------------------------------------
echo "➤ Configurando UFW..."
ufw allow 22/tcp
ufw allow 444/tcp
ufw allow 443/tcp
ufw --force enable

# ----------------------------------------------
# 5. Banner de bienvenida (MOTD)
# ----------------------------------------------
echo "➤ Configurando mensaje de bienvenida..."
cat > $MOTD_FILE <<'EOM'

Bienvenido a tu VPS ⚡️ by Burgos 🚀

EOM

# ----------------------------------------------
# 6. Descargar menú Burgos desde GitHub
# ----------------------------------------------
echo "➤ Instalando menú Burgos..."
wget -O $SCRIPT_PATH https://raw.githubusercontent.com/Burgos9618/Menu-Burgos/main/menu.sh
chmod +x $SCRIPT_PATH
ln -sf $SCRIPT_PATH $INSTALL_PATH

# ----------------------------------------------
# 7. Autoinicio del menú al entrar por SSH
# ----------------------------------------------
if ! grep -q "$INSTALL_PATH" ~/.bashrc; then
    echo "$INSTALL_PATH" >> ~/.bashrc
fi

echo "============================================"
echo " ✅ Instalación completada"
echo " Ejecuta el menú con: menu"
echo "============================================"
