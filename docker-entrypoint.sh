#!/bin/sh

chown -v root:root /var/keys

chown -R opendkim:opendkim /var/keys/dkim
chmod -R 700 /var/keys/dkim

chown -R vmail:vmail /var/vmail
chmod -R u+rw,g+rw,o= /var/vmail

chown -R mysql:mysql /var/lib/mysql
chmod -R u+rw,g+rw,o= /var/lib/mysql

/usr/sbin/rsyslogd

service ssh start
service mysql start
service nginx start
service postfix start
service dovecot start
service opendkim start
service opendmarc start
service spamassassin start

exec "$@"
