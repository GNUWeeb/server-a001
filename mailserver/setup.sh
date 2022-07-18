#!/bin/sh

set -e
cd "$(dirname "$0")"
export DEBIAN_FRONTEND=noninteractive

# Import mounted docker secret file
. /run/secrets/config

MAIL_SSL_KEY="/var/keys/ssl/privkey.pem"
MAIL_SSL_CERT="/var/keys/ssl/fullchain.pem"
DKIM_KEY="/var/keys/dkim/${DKIM_SELECTOR}.private"



#
# User and group
#
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /var/mail
install -v -d -m 0750 -o vmail -g vmail /var/vmail
adduser postfix opendkim
adduser postfix opendmarc



#
# Postfix
#
cp -v ./postfix/*.cf /etc/postfix/

postconf myhostname="$MAIL_HOST"
postconf smtpd_tls_key_file="$MAIL_SSL_KEY"
postconf smtpd_tls_cert_file="$MAIL_SSL_CERT"
postconf relay_domains="$MAIL_RELAY_HOST"

# MySQL user maps
cat << EOF > /etc/postfix/mysql_mailbox_maps.cf
hosts    = ${DB_HOST}
user     = ${DB_USER}
password = ${DB_PASS}
dbname   = ${DB_NAME}
query    = SELECT CONCAT(username, "/") FROM users WHERE username="%u"
EOF

echo "${MAIL_RELAY_HOST} public-inbox: " > /etc/postfix/transport
echo "${MAIL_RELAY_USER}@${MAIL_HOST} ${MAIL_RELAY_USER}@${MAIL_RELAY_HOST}" > /etc/postfix/virtual_aliases

postmap /etc/postfix/transport /etc/postfix/virtual_aliases


# Add public-inbox handler
cat << EOF >> /etc/postfix/master.cf
# Public inbox
public-inbox unix  -      n       n       -       -       pipe
  flags=FR user=${MAIN_USER} argv=/home/${MAIN_USER}/public_inbox.php
EOF

chown -v postfix:postfix /etc/postfix/mysql_mailbox_maps.cf
chmod -v 0600 /etc/postfix/mysql_mailbox_maps.cf



#
# Dovecot
#
install -dv -m 0750 -o dovecot -g postfix /var/spool/postfix/dovecot
cp -v ./dovecot/dovecot.conf /etc/dovecot/

echo "ssl_cert = <${MAIL_SSL_CERT}" >> /etc/dovecot/dovecot.conf
echo "ssl_key = <${MAIL_SSL_KEY}" >> /etc/dovecot/dovecot.conf

# MySQL auth maps
cat << EOF > /etc/dovecot/mysql_auth.conf
driver = mysql
connect = "host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} password=${DB_PASS}"
default_pass_scheme = SHA512-CRYPT
password_query = SELECT username AS user, password \
                 FROM users \
                 WHERE username='%n'
EOF

chown -v dovecot:dovecot /etc/dovecot/mysql_auth.conf
chmod -v 0600 /etc/dovecot/mysql_auth.conf
cp -v ./dovecot/dovecot /etc/init.d/dovecot



#
# OpenDKIM
#
install -dv -m 0750 -o opendkim -g postfix /var/spool/postfix/opendkim

cat << EOF > /etc/opendkim.conf
Domain           ${MAIL_HOST}
Selector         ${DKIM_SELECTOR}
KeyFile          ${DKIM_KEY}
Socket           local:/var/spool/postfix/opendkim/opendkim.sock
Syslog           Yes
Canonicalization relaxed/simple
UMask            002
EOF



#
# OpenDMARC
#
install -dv -m 0750 -o opendmarc -g postfix /var/spool/postfix/opendmarc

cat << EOF > /etc/opendmarc.conf
PidFile                    /run/opendmarc/opendmarc.pid
PublicSuffixList           /usr/share/publicsuffix/public_suffix_list.dat
Socket                     local:/var/spool/postfix/opendmarc/opendmarc.sock
RejectFailures             true
IgnoreAuthenticatedClients true
UMask                      002
UserID                     opendmarc
EOF
