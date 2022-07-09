#!/bin/sh

service ssh start
service nginx start
service mysql start

service postfix start
service dovecot start
service opendkim start
service opendmarc start

exec "$@"
