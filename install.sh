#!/bin/bash
# ================================
#  VPS BURGOS - INSTALLER (CLIENTE)
# ================================

# 🔧 CONFIGURACIÓN DEL KEYSERVER (TU VPS PERSONAL)
KEYSERVER="185.220.205.14"
SSH_KEY="/root/.ssh/id_rsa"   # 🔑 Ruta de tu llave privada

clear
echo "======================================"
echo " 🔐 VPS BURGOS - Instalador seguro"
echo "======================================"
echo ""
echo -n "👉 Ingrese su KEY de instalación: "
read USER_KEY

# 🚨 VALIDAR LA KEY EN EL KEYSERVER
if ssh -i $SSH_KEY -o StrictHostKeyChecking=no root@$KEYSERVER "[ -f /root/keys/$USER_KEY.txt ]"; then
    echo "✅ KEY válida, comenzando instalación..."
    # 🔥 Eliminar la KEY para que no pueda reutilizarse
    ssh -i $SSH_KEY root@$KEYSERVER "rm -f /root/keys/$USER_KEY.txt"
else
    echo "❌ KEY inválida o ya usada."
    exit 1
fi

# ================================
# AQUI VA TU INSTALADOR REAL
# ================================
echo ""
echo "⚙️ Configurando servidor..."
sleep 2

# Actualizar e instalar paquetes
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget unzip ufw git

# Descargar menú desde GitHub
cd /root
rm -rf Menu-Burgos
git clone https://github.com/Burgos9618/Menu-Burgos.git
cd Menu-Burgos
chmod +x menu.sh

# Crear acceso directo
ln -sf /root/Menu-Burgos/menu.sh /usr/bin/burgos

echo ""
echo "======================================"
echo " 🎉 Instalación completada"
echo "👉 Ejecuta: burgos"
echo "======================================"
