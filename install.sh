#!/bin/bash
# ============================================
#   INSTALADOR VPS BURGOS - SSH + STUNNEL
# ============================================

echo "============================================"
echo "      INSTALADOR VPS BURGOS"
echo "============================================"

# Actualizar sistema
apt update -y && apt upgrade -y

# Instalar paquetes necesarios
apt install -y stunnel4 openssh-server apache2

# Habilitar root login en SSH
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh

# Crear certificado autofirmado para stunnel
openssl req -new -x509 -days 365 -nodes -subj "/CN=VPS-BURGOS" \
    -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem
chmod 600 /etc/stunnel/stunnel.pem

# Configuración de stunnel
cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ssh-443]
accept = 443
connect = 22

[ssh-444]
accept = 444
connect = 22

[ssh-445]
accept = 445
connect = 22
EOF

# Crear directorio para PID
mkdir -p /var/run/stunnel4
chown stunnel4:stunnel4 /var/run/stunnel4

# Habilitar stunnel en el arranque
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4

# Reiniciar servicios
systemctl restart ssh
systemctl restart apache2
systemctl restart stunnel4
systemctl enable ssh
systemctl enable apache2
systemctl enable stunnel4

echo "============================================"
echo " Instalación completa!"
echo " Puertos SSL habilitados: 443, 444, 445"
echo " Puerto SSH habilitado: 22"
echo "============================================"