#!/bin/bash
#Aquest Codi té una funcio d'errors per a que et donis compte si falla algun pas
# Variables
DOMAIN="example.com"
ORG="ExampleOrg"
ADMIN_PASSWORD="adminpassword"
LDAP_BASE="dc=example,dc=com"

# Función para manejar errores
handle_error() {
    echo "Error en la línea $1: $2"
    exit 1
}

# Verificar si el script se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   handle_error ${LINENO} "Aquest script s'ha d'executar com a root. Fes servir sudo."
fi

# Actualizar sistema e instalar paquetes necesarios
apt update && apt upgrade -y || handle_error ${LINENO} "Error actualizando el sistema."
DEBIAN_FRONTEND=noninteractive apt install -y slapd ldap-utils libnss-ldap libpam-ldap nslcd || handle_error ${LINENO} "Error instalando paquetes necesarios."

# Configurar slapd automáticamente
{
    echo "slapd slapd/internal/generated_adminpw password $ADMIN_PASSWORD"
    echo "slapd slapd/internal/adminpw password $ADMIN_PASSWORD"
    echo "slapd slapd/domain string $DOMAIN"
    echo "slapd shared/organization string $ORG"
    echo "slapd slapd/no_configuration boolean false"
    echo "slapd slapd/password1 password $ADMIN_PASSWORD"
    echo "slapd slapd/password2 password $ADMIN_PASSWORD"
} | debconf-set-selections || handle_error ${LINENO} "Error configurando slapd."

DEBIAN_FRONTEND=noninteractive dpkg-reconfigure slapd || handle_error ${LINENO} "Error reconfigurando slapd."

# Verificar instalación
slapcat || handle_error ${LINENO} "Error: slapd no se instaló correctamente."

# Crear archivos LDIF para agregar unidades organizativas, grupos y usuarios
cat <<EOF > base.ldif
dn: ou=users,$LDAP_BASE
objectClass: organizationalUnit
ou: users
EOF

ldapadd -x -D "cn=admin,$LDAP_BASE" -w $ADMIN_PASSWORD -f base.ldif || handle_error ${LINENO} "Error al agregar la unidad organizativa."

cat <<EOF > grp.ldif
dn: cn=developers,ou=users,$LDAP_BASE
objectClass: posixGroup
cn: developers
gidNumber: 1001
EOF

ldapadd -x -D "cn=admin,$LDAP_BASE" -w $ADMIN_PASSWORD -f grp.ldif || handle_error ${LINENO} "Error al agregar el grupo."

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

ldapadd -x -D "cn=admin,$LDAP_BASE" -w $ADMIN_PASSWORD -f user.ldif || handle_error ${LINENO} "Error al agregar el usuario."

# Configurar NSS y PAM para autenticación LDAP
sed -i '/passwd:/ s/$/ ldap/' /etc/nsswitch.conf || handle_error ${LINENO} "Error al modificar /etc/nsswitch.conf para passwd."
sed -i '/group:/ s/$/ ldap/' /etc/nsswitch.conf || handle_error ${LINENO} "Error al modificar /etc/nsswitch.conf para group."
sed -i '/shadow:/ s/$/ ldap/' /etc/nsswitch.conf || handle_error ${LINENO} "Error al modificar /etc/nsswitch.conf para shadow."

echo "session required pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session || handle_error ${LINENO} "Error al modificar /etc/pam.d/common-session."

# Comprobar configuración
getent passwd asixero && echo "Usuario asixero configurado correctamente." || handle_error ${LINENO} "Error: Usuario asixero no configurado correctamente."

echo "Configuración LDAP completada con éxito."
