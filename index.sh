#!/bin/bash

# Variables
DOMAIN="example.com"
ORG="ExampleOrg"
ADMIN_PASSWORD="adminpassword"
LDAP_BASE="dc=example,dc=com"

# Verificar si el script se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   echo "Aquest script s'ha d'executar com a root. Fes servir sudo."
   exit 1
fi

# Actualizar sistema e instalar paquetes necesarios
apt update && apt upgrade -y
DEBIAN_FRONTEND=noninteractive apt install -y slapd ldap-utils libnss-ldap libpam-ldap nslcd

# Configurar slapd automáticamente
echo "slapd slapd/internal/generated_adminpw password $ADMIN_PASSWORD" | debconf-set-selections
echo "slapd slapd/internal/adminpw password $ADMIN_PASSWORD" | debconf-set-selections
echo "slapd slapd/domain string $DOMAIN" | debconf-set-selections
echo "slapd shared/organization string $ORG" | debconf-set-selections
echo "slapd slapd/no_configuration boolean false" | debconf-set-selections
echo "slapd slapd/password1 password $ADMIN_PASSWORD" | debconf-set-selections
echo "slapd slapd/password2 password $ADMIN_PASSWORD" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure slapd

# Verificar instalación
slapcat || { echo "Error: slapd no se instaló correctamente"; exit 1; }

# Crear archivos LDIF para agregar unidades organizativas, grupos y usuarios
cat <<EOF > base.ldif
dn: ou=users,$LDAP_BASE
objectClass: organizationalUnit
ou: users
EOF

ldapadd -x -D "cn=admin,$LDAP_BASE" -w $ADMIN_PASSWORD -f base.ldif || { echo "Error al agregar la unidad organizativa"; exit 1; }

cat <<EOF > grp.ldif
dn: cn=developers,ou=users,$LDAP_BASE
objectClass: posixGroup
cn: developers
gidNumber: 1001
EOF

ldapadd -x -D "cn=admin,$LDAP_BASE" -w $ADMIN_PASSWORD -f grp.ldif || { echo "Error al agregar el grupo"; exit 1; }

USER_PASSWORD_HASH=$(slappasswd -s "userpassword")

cat <<EOF > user.ldif
dn: uid=asixero,ou=users,$LDAP_BASE
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
userPassword: $USER_PASSWORD_HASH
EOF

ldapadd -x -D "cn=admin,$LDAP_BASE" -w $ADMIN_PASSWORD -f user.ldif || { echo "Error al agregar el usuario"; exit 1; }

# Configurar NSS y PAM para autenticación LDAP
sed -i '/passwd:/ s/$/ ldap/' /etc/nsswitch.conf
sed -i '/group:/ s/$/ ldap/' /etc/nsswitch.conf
sed -i '/shadow:/ s/$/ ldap/' /etc/nsswitch.conf

echo "session required pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session

# Comprobar configuración
getent passwd asixero && echo "Usuario asixero configurado correctamente."

echo "Configuración LDAP completada con éxito."
