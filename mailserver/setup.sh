#!/bin/sh

set -e
cd "$(dirname "$0")"
export DEBIAN_FRONTEND=noninteractive

# Import mounted docker secret file
. /run/secrets/config



#
# User and group
#
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /var/mail
install -v -d -m 0750 -o vmail -g vmail /var/vmail
