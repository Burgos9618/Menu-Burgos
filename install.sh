#!/bin/bash
# ==============================================
# Instalador VPS Burgos
# Configura: SSH, Stunnel (SSL), Firewall y Menú
# ==============================================

INSTALL_PATH="/usr/local/bin/menu"
SCRIPT_PATH="/usr/local/bin/menu_admin.sh"
MOTD_FILE="/etc/motd"

echo "============================================"
echo " 🚀 Instalador VPS Burgos"
echo "============================================"

# 1. Actualizar sistema e instalar dependencias
apt-get update -y && apt-get upgrade -y
apt-get install -y dropbear stunnel4 net-tools ufw curl git gawk screen

# 2. Configurar SSH (22 y 444)
echo "➤ Configurando SSH..."
sed -i '/^Port /d' /etc/ssh/sshd_config
echo "Port 22" >> /etc/ssh/sshd_config
echo "Port 444" >> /etc/ssh/sshd_config
systemctl restart sshd

# 3. Configurar Stunnel (443, 445, 446 → 22)
echo "➤ Configurando Stunnel..."
mkdir -p /etc/stunnel

# Generar certificado si no existe
if [ ! -f /etc/stunnel/stunnel.pem ]; then
  openssl req -new -x509 -days 365 -nodes -subj "/CN=burgos-vps" \
  -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem
  chmod 600 /etc/stunnel/stunnel.pem
fi

# Crear configuración de stunnel
cat > /etc/stunnel/stunnel.conf <<'EOF'
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
foreground = no
client = no
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ssh-443]
accept = 443
connect = 22

[ssh-445]
accept = 445
connect = 22

[ssh-446]
accept = 446
connect = 22
EOF

# Habilitar stunnel
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
systemctl restart stunnel4
systemctl enable stunnel4

# 4. Configurar firewall UFW
echo "➤ Configurando firewall..."
ufw allow 22/tcp
ufw allow 444/tcp
ufw allow 443/tcp
ufw allow 445/tcp
ufw allow 446/tcp
ufw --force enable

# 5. MOTD personalizado
cat > $MOTD_FILE <<'EOM'
============================================
 ⚡️ VPS Burgos instalado con éxito
 Usa "menu" para administrar tu servidor
============================================
EOM

# 6. Crear menú básico de administración
cat > $SCRIPT_PATH <<'EOF'
#!/bin/bash
clear
echo "============================================"
echo "         📌 Menú de Administración VPS"
echo "============================================"
echo "1) Crear usuario"
echo "2) Eliminar usuario"
echo "3) Listar usuarios"
echo "4) Ver conexiones activas"
echo "5) Salir"
echo "============================================"
read -p "Elige una opción: " opcion

case \$opcion in
  1)
    read -p "Usuario: " user
    read -p "Contraseña: " pass
    read -p "Días válidos: " dias
    useradd -M -s /bin/false \$user
    echo "\$user:\$pass" | chpasswd
    chage -E $(date -d "+\$dias days" +%Y-%m-%d) \$user
    echo "✅ Usuario \$user creado por \$dias días"
    ;;
  2)
    read -p "Usuario a eliminar: " user
    userdel -r \$user
    echo "🗑️ Usuario \$user eliminado"
    ;;
  3)
    echo "👥 Usuarios en el sistema:"
    cut -d: -f1 /etc/passwd | grep -E -v "^(root|nobody)"
    ;;
  4)
    echo "📡 Conexiones activas SSH:"
    netstat -tnpa | grep 'ESTABLISHED.*sshd'
    ;;
  5)
    exit 0
    ;;
  *)
    echo "❌ Opción inválida"
    ;;
esac
EOF

chmod +x $SCRIPT_PATH
ln -sf $SCRIPT_PATH $INSTALL_PATH

# 7. Autoinicio del menú al entrar por SSH
if ! grep -q "$INSTALL_PATH" ~/.bashrc; then
  echo "$INSTALL_PATH" >> ~/.bashrc
fi

echo "============================================"
echo " ✅ Instalación completada"
echo " Ejecuta el menú con: menu"
echo " Puertos SSH: 22, 444"
echo " Puertos SSL: 443, 445, 446"
echo "============================================"
