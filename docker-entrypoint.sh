#!/bin/sh

service ssh start
service nginx start

exec "$@"
