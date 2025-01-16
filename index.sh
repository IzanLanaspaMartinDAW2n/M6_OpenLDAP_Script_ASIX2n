#!/bin/bash

# Variables
DOMAIN="example.com"
ORG="ExampleOrg"
ADMIN_PASSWORD="adminpassword"
LDAP_BASE="dc=example,dc=com"

# Actualizar sistema e instalar paquetes necesarios
apt update && apt upgrade -y
apt install -y slapd ldap-utils libnss-ldap libpam-ldap nslcd

# Configuración de slapd
dpkg-reconfigure slapd <<EOF
no
$DOMAIN
$ORG
$ADMIN_PASSWORD
$ADMIN_PASSWORD
HDB
no
no
EOF

# Verificar instalación
slapcat

# Crear archivo para estructura de directorio
echo "dn: ou=users,$LDAP_BASE
objectClass: organizationalUnit
ou: users" > base.ldif

# Agregar unidad organizativa
ldapadd -x -D "cn=admin,$LDAP_BASE" -w $ADMIN_PASSWORD -f base.ldif

# Crear archivo para grupo
echo "dn: cn=developers,ou=users,$LDAP_BASE
objectClass: posixGroup
cn: developers
gidNumber: 1001" > grp.ldif

# Agregar grupo
ldapadd -x -D "cn=admin,$LDAP_BASE" -w $ADMIN_PASSWORD -f grp.ldif

# Crear hash de contraseña para usuario
USER_PASSWORD_HASH=$(slappasswd -s "userpassword")

# Crear archivo para usuario
echo "dn: uid=asixero,ou=users,$LDAP_BASE
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
cn: Asixero
sn: Usuario
uid: asixero
uidNumber: 1001
gidNumber: 1001
homeDirectory: /home/asixero
loginShell: /bin/bash
userPassword: $USER_PASSWORD_HASH" > user.ldif

# Agregar usuario
ldapadd -x -D "cn=admin,$LDAP_BASE" -w $ADMIN_PASSWORD -f user.ldif

# Verificar adiciones
slapcat | grep asixero
ldapsearch -x -LLL -b "$LDAP_BASE" "uid=asixero"

# Configurar NSS y PAM para autenticación LDAP
sed -i '/passwd:/ s/$/ ldap/' /etc/nsswitch.conf
sed -i '/group:/ s/$/ ldap/' /etc/nsswitch.conf
sed -i '/shadow:/ s/$/ ldap/' /etc/nsswitch.conf

echo "session required pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session

# Comprobar configuración
getent passwd asixero

# Finalización
echo "Configuración LDAP completada con éxito."
