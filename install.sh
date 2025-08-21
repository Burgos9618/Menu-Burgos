#!/bin/bash
# Script de instalación Panel SSH - VPS
# Autor: Burgos Edition

clear
echo "=================================="
echo "  Instalando dependencias..."
echo "=================================="
apt update -y && apt upgrade -y
apt install -y wget curl unzip figlet lolcat gawk net-tools screen

# Instalar servicios base
apt install -y openssh-server dropbear stunnel4

# --- CONFIGURAR SSH ---
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
systemctl restart ssh

# --- CONFIGURAR DROPBEAR ---
echo "/bin/false" >> /etc/shells
cat <<EOF > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=444
DROPBEAR_EXTRA_ARGS="-p 80"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
EOF
systemctl enable dropbear
systemctl restart dropbear

# --- CONFIGURAR STUNNEL ---
mkdir -p /etc/stunnel
cat <<EOF > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ssh-443]
accept = 443
connect = 22

[ssh-444]
accept = 444
connect = 22
EOF

# Generar certificado SSL autofirmado
openssl req -new -x509 -days 365 -nodes -subj "/CN=SSHPanel" -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem
chmod 600 /etc/stunnel/stunnel.pem
systemctl enable stunnel4
systemctl restart stunnel4

# --- INSTALAR BADVPN ---
wget -O /usr/bin/badvpn-udpgw https://github.com/ambrop72/badvpn/releases/download/1.999.130/badvpn-udpgw
chmod +x /usr/bin/badvpn-udpgw
screen -dmS badvpn /usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000

# --- CREAR MENU ---
cat <<'EOF' > /usr/bin/menu
#!/bin/bash
while true; do
clear
echo "========== PANEL SSH =========="
echo "1) Crear usuario SSH"
echo "2) Listar usuarios"
echo "3) Eliminar usuario"
echo "4) Ver conexiones activas"
echo "0) Salir"
read -p "Elige una opción: " opcion
case \$opcion in
  1)
    read -p "Usuario: " user
    read -p "Contraseña: " pass
    read -p "Días de validez: " dias
    useradd -e \$(date -d "+\$dias days" +"%Y-%m-%d") -M -s /bin/false \$user
    (echo \$pass; echo \$pass) | passwd \$user
    echo "Usuario \$user creado con éxito!"
    ;;
  2)
    cut -d: -f1 /etc/passwd
    ;;
  3)
    read -p "Usuario a eliminar: " userdel
    userdel -r \$userdel
    echo "Usuario eliminado."
    ;;
  4)
    echo "Conexiones activas:"
    netstat -tnpa | grep 'ESTABLISHED.*sshd'
    ;;
  0)
    exit
    ;;
  *)
    echo "Opción inválida"
    ;;
esac
read -p "Presiona enter para continuar..."
done
EOF

chmod +x /usr/bin/menu

clear
echo "=================================="
echo " Instalación completada!"
echo " Usa el comando: menu"
echo "=================================="