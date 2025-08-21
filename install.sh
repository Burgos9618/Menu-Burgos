#!/bin/bash
# =====================================================
# Script de instalación y configuración VPS
# Autor: Tu Configuración VPS
# =====================================================

clear
echo "===================================="
echo "  🚀 Instalando y configurando VPS"
echo "===================================="
sleep 2

# --- Actualizar sistema ---
apt update -y && apt upgrade -y

# --- Instalar dependencias ---
apt install -y gawk curl wget sudo screen ufw stunnel4

# --- Configuración SSH ---
echo "➡ Habilitando SSH en puertos 22 y 444..."
if ! grep -q "Port 444" /etc/ssh/sshd_config; then
  echo "Port 444" >> /etc/ssh/sshd_config
fi
systemctl restart ssh

# --- Generar certificado SSL ---
echo "➡ Generando certificado SSL para stunnel..."
mkdir -p /etc/stunnel
openssl req -new -x509 -days 365 -nodes -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem \
-subj "/C=US/ST=World/L=VPS/O=VPS/OU=IT/CN=$(hostname)"
chmod 600 /etc/stunnel/stunnel.pem

# --- Configuración Stunnel ---
echo "➡ Configurando Stunnel..."
cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no

[ssh-443]
accept = 443
connect = 22

[ssh-444]
accept = 444
connect = 22

[ssh-445]
accept = 445
connect = 22

[ssh-446]
accept = 446
connect = 22
EOF

# --- Activar Stunnel ---
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
systemctl restart stunnel4
systemctl enable stunnel4

# --- Configuración Firewall ---
echo "➡ Configurando firewall (UFW)..."
ufw allow 22/tcp
ufw allow 443/tcp
ufw allow 444/tcp
ufw allow 445/tcp
ufw allow 446/tcp
ufw --force enable

# --- Finalización ---
clear
echo "===================================="
echo "✅ Instalación completada"
echo "------------------------------------"
echo " Puertos SSH habilitados: 22, 444"
echo " Puertos SSL habilitados: 443, 444, 445, 446"
echo " Puedes crear usuarios con:"
echo "   adduser usuario"
echo "===================================="