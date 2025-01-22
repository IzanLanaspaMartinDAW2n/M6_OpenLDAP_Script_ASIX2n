#!/bin/bash

# Solicitar la IP del servidor LDAP
echo "Introduce la IP del servidor LDAP:"
read LDAP_SERVER_IP

# Verificar si la IP es válida
if [[ ! $LDAP_SERVER_IP =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    echo "Error: La IP introducida no es válida."
    exit 1
fi

# Variables
LDAP_BASE="dc=example,dc=com"  # Cambiar al dominio correcto
LDAP_ADMIN_DN="cn=admin,$LDAP_BASE"  # DN del administrador
LDAP_ADMIN_PASSWORD="adminpassword"  # Cambiar por la contraseña correcta

# Actualizar sistema e instalar paquetes necesarios
apt update && apt upgrade -y
apt install -y libnss-ldap libpam-ldap ldap-utils nslcd

# Configurar NSS y PAM para autenticación LDAP
cat <<EOF | debconf-set-selections
libnss-ldap libnss-ldap/ldapns/ldap-server string ldap://$LDAP_SERVER_IP
libnss-ldap libnss-ldap/ldapns/base-dn string $LDAP_BASE
libnss-ldap libnss-ldap/ldapns/ldap_version select 3
libpam-runtime libpam-runtime/profiles multiselect unix, ldap
EOF

dpkg-reconfigure -f noninteractive libnss-ldap libpam-ldap nslcd

# Editar /etc/nsswitch.conf para incluir LDAP
echo "Modificando /etc/nsswitch.conf para usar LDAP"
sed -i '/passwd:/ s/$/ ldap/' /etc/nsswitch.conf
sed -i '/group:/ s/$/ ldap/' /etc/nsswitch.conf
sed -i '/shadow:/ s/$/ ldap/' /etc/nsswitch.conf

# Configurar PAM para crear directorios personales automáticamente
echo "session required pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session

# Probar configuración
ldapsearch -x -H ldap://$LDAP_SERVER_IP -D "$LDAP_ADMIN_DN" -w "$LDAP_ADMIN_PASSWORD" -b "$LDAP_BASE" || {
    echo "Error: No se pudo conectar al servidor LDAP. Verifique la IP, DN y contraseña."
    exit 1
}

# Finalización
echo "Configuración del cliente LDAP completada con éxito. Prueba autenticación con getent passwd."
