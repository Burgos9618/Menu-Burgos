# 🚀 VPS Burgos - Menú SSH/SSL Manager

Script de instalación automática para configurar **Stunnel4 (SSL/SSH)** y un **menú interactivo** de gestión de usuarios, puertos y banner de bienvenida.  
Ideal para administrar tu VPS de forma rápida y segura.

---

## 🔧 Instalación

Ejecuta el siguiente comando en tu VPS recién instalado (Ubuntu/Debian):

```bash
bash <(curl -s https://raw.githubusercontent.com/Burgos9618/Menu-Burgos/main/install.sh)

Esto instalará automáticamente:
	•	Dependencias necesarias (stunnel4, openssl, etc.)
	•	Configuración inicial de Stunnel (SSL 443 -> SSH 22)
	•	Menú de gestión SSH/SSL
	•	Banner de bienvenida en conexiones SSH
    
📜 Uso del menú

Una vez instalado, puedes ejecutar el menú con:
menu

Opciones disponibles:
	1.	Crear usuario SSH → Genera un nuevo usuario con fecha de expiración.
	2.	Editar usuario SSH → Cambia contraseña y fecha de expiración.
	3.	Listar usuarios SSH → Muestra los usuarios activos.
	4.	Bloquear usuario SSH → Suspende temporalmente un usuario.
	5.	Desbloquear usuario SSH → Reactiva un usuario bloqueado.
	6.	Eliminar usuario SSH → Elimina definitivamente un usuario.
	7.	Abrir nuevo puerto SSH → Agrega otro puerto de acceso SSH.
	8.	Abrir nuevo puerto SSL → Agrega otro puerto SSL sobre Stunnel.
	9.	Salir → Cierra el menú.
    
📌 Notas importantes
	•	Por defecto, el puerto SSH es 22 y el puerto SSL es 443.
	•	Puedes abrir más puertos desde el menú.
	•	Los usuarios creados se almacenan en /root/usuarios_ssh/ con sus credenciales.
	•	Recomendado usar en un VPS limpio para evitar conflictos.


💜 Autor

Desarrollado por VPS Burgos
📱 WhatsApp: 9851169633
📬 Telegram: @Escanor_Sama18

    