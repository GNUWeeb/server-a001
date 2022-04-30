#!/bin/sh

service ssh start
service nginx start
service mysql start

exec "$@"
