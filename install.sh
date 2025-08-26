#!/bin/bash
# ===== VPS BURGOS – Gestor con degradado azul→morado =====

[[ $EUID -ne 0 ]] && { echo "Ejecute como root."; exit 1; }

# ---------- Utilidades de entorno ----------
get_ip() { hostname -I 2>/dev/null | awk '{print $1}'; }
get_ssh_port() {
  local p
  p=$(awk '/^[Pp]ort[[:space:]]+[0-9]+/ {print $2}' /etc/ssh/sshd_config | tail -n1)
  [[ -z "$p" ]] && p=22
  echo "$p"
}
get_ssl_port() {
  local p
  [[ -f /etc/stunnel/stunnel.conf ]] && \
    p=$(awk '/^[[:space:]]*accept[[:space:]]*=/{print $3}' /etc/stunnel/stunnel.conf | awk -F: '{print $NF}' | tail -n1)
  [[ -z "$p" ]] && p=$(ss -tlnp 2>/dev/null | awk '/stunnel/{sub(/.*:/,"",$4);print $4;exit}')
  echo "${p:-444}"
}

# ---------- Degradado azul -> morado (línea por línea) ----------
GRADIENT=(33 69 75 81 99 129 135 141 177 183 219)
RESET="\e[0m"
_line_idx=0

eco_grad() {
  local color=${GRADIENT[$((_line_idx % ${#GRADIENT[@]}))]}
  echo -e "\e[38;5;${color}m$*${RESET}"
  ((_line_idx++))
}
eco_grad_n() {
  local color=${GRADIENT[$((_line_idx % ${#GRADIENT[@]}))]}
  printf "\e[38;5;${color}m%s${RESET}" "$*"
  ((_line_idx++))
}
reset_grad() { _line_idx=0; }

# ---------- Helpers de usuarios ----------
solo_usuarios_ssh() { awk -F: '$3>=1000 && $1!="nobody"{print $1}' /etc/passwd; }

crear_usuario() {
  reset_grad; clear
  eco_grad "=== Crear usuario SSH ==="
  eco_grad_n "Usuario: "; read -r user
  [[ -z "$user" ]] && { eco_grad "Cancelado."; return; }
  id "$user" &>/dev/null && { eco_grad "❌ Ya existe."; return; }
  eco_grad_n "Contraseña: "; read -r pass
  eco_grad_n "Días de duración: "; read -r dias
  [[ -z "$dias" || ! "$dias" =~ ^[0-9]+$ ]] && { eco_grad "❌ Días inválidos."; return; }

  expira=$(date -d "+$dias days" +"%Y-%m-%d")
  useradd -e "$expira" -M -s /bin/false "$user" || { eco_grad "❌ Error al crear."; return; }
  echo "$user:$pass" | chpasswd

  mkdir -p /root/usuarios_ssh
  ficha="/root/usuarios_ssh/$user.txt"
  cat <<EOF > "$ficha"
===== SSH BURGOS =====
Usuario: $user
Contraseña: $pass
Expira: $expira
IP: $(get_ip)
Puerto SSH: $(get_ssh_port)
Puerto SSL: $(get_ssl_port)
======================
EOF

  # --- Mostrar en pantalla ---
  eco_grad ""
  eco_grad "===== SSH BURGOS ====="
  eco_grad "Usuario: $user"
  eco_grad "Contraseña: $pass"
  eco_grad "Expira: $expira"
  eco_grad "IP: $(get_ip)"
  eco_grad "Puerto SSH: $(get_ssh_port)"
  eco_grad "Puerto SSL: $(get_ssl_port)"
  eco_grad "======================"
  eco_grad "✅ Usuario creado. Ficha guardada en: $ficha"

  # --- Opción para copiar al portapapeles ---
  echo
  eco_grad_n "¿Desea copiar la información al portapapeles? (s/n): "
  read -r copy
  if [[ "$copy" =~ ^[sS]$ ]]; then
    if command -v xclip &>/dev/null; then
      cat "$ficha" | xclip -selection clipboard
      eco_grad "📋 Información copiada al portapapeles con xclip."
    elif command -v xsel &>/dev/null; then
      cat "$ficha" | xsel --clipboard --input
      eco_grad "📋 Información copiada al portapapeles con xsel."
    elif command -v pbcopy &>/dev/null; then
      cat "$ficha" | pbcopy
      eco_grad "📋 Información copiada al portapapeles con pbcopy (Mac)."
    elif command -v termux-clipboard-set &>/dev/null; then
      cat "$ficha" | termux-clipboard-set
      eco_grad "📋 Información copiada al portapapeles en Termux."
    else
      eco_grad "⚠️ No se encontró una utilidad para copiar al portapapeles."
    fi
  fi
}

editar_usuario() {
  reset_grad; clear
  eco_grad "=== Editar usuario SSH ==="
  mapfile -t usuarios < <(solo_usuarios_ssh); usuarios+=("0) Cancelar")
  [[ ${#usuarios[@]} -eq 1 ]] && { eco_grad "No hay usuarios."; return; }

  local i=1
  for u in "${usuarios[@]:0:${#usuarios[@]}-1}"; do eco_grad "$i) $u"; ((i++)); done
  eco_grad "0) Cancelar"
  eco_grad_n "Seleccione: "; read -r sel
  [[ "$sel" == "0" ]] && return
  user="${usuarios[$((sel-1))]}"
  id "$user" &>/dev/null || { eco_grad "Inválido."; return; }

  eco_grad_n "Nueva contraseña (ENTER para omitir): "; read -r pass
  [[ -n "$pass" ]] && echo "$user:$pass" | chpasswd
  eco_grad_n "Nuevos días (ENTER para omitir): "; read -r dias
  if [[ -n "$dias" && "$dias" =~ ^[0-9]+$ ]]; then
    expira=$(date -d "+$dias days" +"%Y-%m-%d")
    chage -E "$expira" "$user"
    eco_grad "Nueva expiración: $expira"
  fi
  eco_grad "✅ Usuario actualizado."
}

listar_usuarios() {
  reset_grad; clear
  eco_grad "=== Listar usuarios SSH ==="
  local found=0
  while IFS=: read -r name _ uid _ _ _ _; do
    [[ $uid -ge 1000 && $name != "nobody" ]] || continue
    found=1
    exp=$(chage -l "$name" 2>/dev/null | awk -F': ' '/Account expires/{print $2}')
    eco_grad "• $name  (expira: ${exp:-desconocido})"
  done < /etc/passwd
  [[ $found -eq 0 ]] && eco_grad "No hay usuarios."
}

bloquear_usuario() {
  reset_grad; clear
  eco_grad "=== Bloquear usuario SSH ==="
  eco_grad_n "Usuario: "; read -r user
  id "$user" &>/dev/null || { eco_grad "No existe."; return; }
  passwd -l "$user" &>/dev/null && eco_grad "🔒 Bloqueado."
}

desbloquear_usuario() {
  reset_grad; clear
  eco_grad "=== Desbloquear usuario SSH ==="
  eco_grad_n "Usuario: "; read -r user
  id "$user" &>/dev/null || { eco_grad "No existe."; return; }
  passwd -u "$user" &>/dev/null && eco_grad "🔓 Desbloqueado."
}

eliminar_usuario() {
  reset_grad; clear
  eco_grad "=== Eliminar usuario SSH ==="
  mapfile -t usuarios < <(solo_usuarios_ssh); usuarios+=("0) Cancelar")
  [[ ${#usuarios[@]} -eq 1 ]] && { eco_grad "No hay usuarios."; return; }

  local i=1
  for u in "${usuarios[@]:0:${#usuarios[@]}-1}"; do
    eco_grad "$i) $u"
    ((i++))
  done
  eco_grad "0) Cancelar"
  eco_grad_n "Seleccione: "; read -r sel
  [[ "$sel" == "0" ]] && return
  user="${usuarios[$((sel-1))]}"
  id "$user" &>/dev/null || { eco_grad "Inválido."; return; }

  userdel -r "$user" 2>/dev/null
  rm -f "/root/usuarios_ssh/$user.txt"
  eco_grad "🗑 Usuario $user eliminado."
}

# ---------- Herramientas ----------
monitorear_usuarios() {
  reset_grad; clear
  eco_grad "=== Usuarios conectados ==="
  who || true
  echo
  eco_grad "=== Conexiones TCP establecidas por IP ==="
  ss -tn state established 2>/dev/null | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr
}

reiniciar_servicios() {
  reset_grad; clear
  eco_grad "🔄 Reiniciando SSH y Stunnel..."
  systemctl restart ssh 2>/dev/null
  systemctl restart stunnel4 2>/dev/null
  eco_grad "✅ Servicios reiniciados."
}

cambiar_puerto_ssh() {
  reset_grad; clear
  eco_grad "=== Cambiar puerto SSH ==="
  eco_grad "Puerto actual: $(get_ssh_port)"
  eco_grad_n "Nuevo puerto: "; read -r p
  [[ ! "$p" =~ ^[0-9]+$ ]] && { eco_grad "❌ Inválido."; return; }
  sed -i "s/^[#[:space:]]*Port[[:space:]]\+[0-9]\+/Port $p/" /etc/ssh/sshd_config
  grep -qE '^[#[:space:]]*Port[[:space:]]' /etc/ssh/sshd_config || echo "Port $p" >> /etc/ssh/sshd_config
  if command -v ufw >/dev/null 2>&1; then
    ufw allow "$p"/tcp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1
  fi
  systemctl restart ssh
  eco_grad "✅ Nuevo puerto SSH: $p"
}

abrir_puertos() {
  reset_grad; clear
  eco_grad "=== Abrir puertos (SSH/SSL) ==="
  local def_ssh def_ssl ports proto
  def_ssh=$(get_ssh_port)
  def_ssl=$(get_ssl_port)
  eco_grad "Detectado -> SSH: $def_ssh  |  SSL: $def_ssl"
  eco_grad_n "Puertos a abrir (separa por espacio/coma, ENTER=$def_ssh $def_ssl): "
  read -r ports
  [[ -z "$ports" ]] && ports="$def_ssh $def_ssl"
  ports=$(echo "$ports" | tr ',' ' ')
  eco_grad_n "Protocolo [tcp/udp/ambos] (ENTER=tcp): "
  read -r proto
  local protos
  case "${proto,,}" in
    udp) protos=(udp) ;;
    ambos|both|tcp+udp) protos=(tcp udp) ;;
    *) protos=(tcp) ;;
  esac

  if command -v ufw >/dev/null 2>&1; then
    for p in $ports; do
      for pr in "${protos[@]}"; do
        ufw allow "$p/$pr" >/dev/null 2>&1
        eco_grad "UFW: permitido $p/$pr"
      done
    done
    ufw reload >/dev/null 2>&1
    eco_grad "✅ Reglas aplicadas en UFW."
  elif command -v firewall-cmd >/dev/null 2>&1; then
    for p in $ports; do
      for pr in "${protos[@]}"; do
        firewall-cmd --permanent --add-port="$p/$pr" >/dev/null 2>&1
        eco_grad "firewalld: agregado $p/$pr"
      done
    done
    firewall-cmd --reload >/dev/null 2>&1
    eco_grad "✅ Reglas aplicadas en firewalld."
  else
    if command -v iptables >/dev/null 2>&1; then
      for p in $ports; do
        for pr in "${protos[@]}"; do
          iptables -I INPUT -p "$pr" --dport "$p" -j ACCEPT
          eco_grad "iptables: ACCEPT $p/$pr"
        done
      done
      if command -v netfilter-persistent >/dev/null 2>&1; then
        netfilter-persistent save >/dev/null 2>&1
        eco_grad "Reglas guardadas con netfilter-persistent."
      fi
      eco_grad "✅ Reglas aplicadas con iptables."
    elif command -v nft >/dev/null 2>&1; then
      for p in $ports; do
        for pr in "${protos[@]}"; do
          nft add rule inet filter input $pr dport $p accept 2>/dev/null
          eco_grad "nftables: accept $p/$pr"
        done
      done
      eco_grad "✅ Reglas aplicadas con nftables (persistencia depende de tu sistema)."
    else
      eco_grad "⚠️ No se detectó firewall administrable automáticamente."
    fi
  fi
}

info_servidor() {
  reset_grad; clear
  eco_grad "=== Información del servidor ==="
  eco_grad "Hostname: $(hostname)"
  eco_grad "IP Pública: $(get_ip)"
  eco_grad "Puerto SSH: $(get_ssh_port)"
  eco_grad "Puerto SSL: $(get_ssl_port)"
  if command -v lsb_release >/dev/null 2>&1; then
    eco_grad "Sistema: $(lsb_release -d | cut -f2)"
  else
    . /etc/os-release 2>/dev/null
    eco_grad "Sistema: ${PRETTY_NAME:-Desconocido}"
  fi
  eco_grad "Kernel: $(uname -r)"
  eco_grad "Uptime: $(uptime -p)"
  eco_grad "RAM libre: $(free -m | awk '/Mem:/{print $4" MB"}')"
}

# ---------- Menús ----------
menu_principal() {
  while :; do
    reset_grad; clear
    eco_grad "==============================="
    eco_grad " 🔐 Bienvenido a VPS Burgos "
    eco_grad " --- Tu conexión segura --- "
    eco_grad "==============================="
    eco_grad ""
    eco_grad "📱 WhatsApp: 9851169633"
    eco_grad "📬 Telegram: @Escanor_Sama18"
    eco_grad ""
    eco_grad "⚠️  Acceso autorizado únicamente."
    eco_grad "🔴 Todo acceso será monitoreado y registrado."
    eco_grad ""
    eco_grad "===== MENU VPS BURGOS ====="
    eco_grad "1) Gestión de usuarios 👤"
    eco_grad "2) Herramientas ⚒️"
    eco_grad "0) Salir"
    eco_grad ""
    eco_grad_n "Seleccione: "; read -r op
    case "$op" in
      1) menu_usuarios ;;
      2) menu_herramientas ;;
      0) clear; exit 0 ;;
      *) eco_grad "Opción inválida"; sleep 1 ;;
    esac
  done
}

menu_usuarios() {
  while :; do
    reset_grad; clear
    eco_grad "==== GESTIÓN DE USUARIOS 👤 ===="
    eco_grad "1) Crear usuario SSH"
    eco_grad "2) Editar usuario SSH"
    eco_grad "3) Listar usuarios SSH"
    eco_grad "4) Bloquear usuario SSH"
    eco_grad "5) Desbloquear usuario SSH"
    eco_grad "6) Eliminar usuario SSH"
    eco_grad "0) Volver"
    eco_grad ""
    eco_grad_n "Seleccione: "; read -r op
    case "$op" in
      1) crear_usuario; read -rp $'\nPresione ENTER para continuar...';;
      2) editar_usuario; read -rp $'\nPresione ENTER para continuar...';;
      3) listar_usuarios; read -rp $'\nPresione ENTER para continuar...';;
      4) bloquear_usuario; read -rp $'\nPresione ENTER para continuar...';;
      5) desbloquear_usuario; read -rp $'\nPresione ENTER para continuar...';;
      6) eliminar_usuario; read -rp $'\nPresione ENTER para continuar...';;
      0) return ;;
      *) eco_grad "Opción inválida"; sleep 1 ;;
    esac
  done
}

menu_herramientas() {
  while :; do
    reset_grad; clear
    eco_grad "===== HERRAMIENTAS ⚒️ ====="
    eco_grad "8) Monitorear usuarios activos"
    eco_grad "9) Reiniciar servicios SSH/SSL"
    eco_grad "10) Cambiar puerto SSH"
    eco_grad "11) Información del servidor"
    eco_grad "12) Abrir puertos (SSH/SSL)"
    eco_grad "0) Volver"
    eco_grad ""
    eco_grad_n "Seleccione: "; read -r op
    case "$op" in
      8) monitorear_usuarios; read -rp $'\nPresione ENTER para continuar...';;
      9) reiniciar_servicios; sleep 1 ;;
      10) cambiar_puerto_ssh; read -rp $'\nPresione ENTER para continuar...';;
      11) info_servidor; read -rp $'\nPresione ENTER para continuar...';;
      12) abrir_puertos; read -rp $'\nPresione ENTER para continuar...';;
      0) return ;;
      *) eco_grad "Opción inválida"; sleep 1 ;;
    esac
  done
}

# ---------- Inicio ----------
menu_principal
