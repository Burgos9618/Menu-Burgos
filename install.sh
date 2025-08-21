#!/bin/bash
# Instalador automático de Stunnel para SSH

echo "=== Instalando dependencias... ==="
apt-get update -y
apt-get install stunnel4 -y

echo "=== Creando certificado SSL... ==="
openssl req -new -x509 -days 365 -nodes -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=stunnel" -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem
chmod 600 /etc/stunnel/stunnel.pem

echo "=== Creando archivo de configuración... ==="
cat > /etc/stunnel/stunnel.conf << EOF
# Archivo de configuración Stunnel

pid = /var/run/stunnel/stunnel.pid
cert = /etc/stunnel/stunnel.pem

foreground = no
client = no
setuid = stunnel4
setgid = stunnel4
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

# Puertos SSL → SSH
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

echo "=== Ajustando permisos... ==="
mkdir -p /var/run/stunnel
chown stunnel4:stunnel4 /var/run/stunnel

echo "=== Activando stunnel4 en el arranque... ==="
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4

systemctl enable stunnel4
systemctl restart stunnel4

echo "=== Instalación completada 🚀 ==="
systemctl status stunnel4 --no-pager