#!/bin/sh

set -e
cd "$(dirname "$0")"
export DEBIAN_FRONTEND=noninteractive

# Import mounted docker secret file
. /run/secrets/config

MAIL_SSL_KEY="/var/keys/ssl/privkey.pem"
MAIL_SSL_CERT="/var/keys/ssl/fullchain.pem"



#
# User and group
#
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /var/mail
install -v -d -m 0750 -o vmail -g vmail /var/vmail



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
