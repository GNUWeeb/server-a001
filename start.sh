#!/bin/bash
set -e;

HOSTNAME="gnuweeb.org";
CONTAINER_NAME="server-a001-ct";
MYSQL_DATA_DIR="./storage/var/lib/mysql";
KEYS_DIR="./storage/var/keys";
VMAIL_DIR="./storage/var/vmail";
EXTRA_DIR="./storage/root/extra";
WWW_DIR="./storage/var/www";
NGINX_DIR="./storage/etc/nginx";

mkdir -pv "${MYSQL_DATA_DIR}";
mkdir -pv "${KEYS_DIR}";
mkdir -pv "${VMAIL_DIR}";
mkdir -pv "${EXTRA_DIR}";
mkdir -pv "${WWW_DIR}";
mkdir -pv "${NGINX_DIR}";

MYSQL_DATA_DIR="$(readlink -e "${MYSQL_DATA_DIR}")";
KEYS_DIR="$(readlink -e "${KEYS_DIR}")";
VMAIL_DIR="$(readlink -e "${VMAIL_DIR}")";
EXTRA_DIR="$(readlink -e "${EXTRA_DIR}")";
WWW_DIR="$(readlink -e "${WWW_DIR}")";
NGINX_DIR="$(readlink -e "${NGINX_DIR}")";

COMMON_MOUNT_OPT="volume-driver=local,volume-opt=type=none,volume-opt=o=bind";

CMD="$1";

if [[ "${CMD}" == "force-run" ]]; then
    docker rm -f "${CONTAINER_NAME}" || true;
    CMD="run";
fi;

if [[ "${CMD}" == "run" ]]; then
    docker run \
        --name "${CONTAINER_NAME}" \
        --privileged \
        --hostname "${HOSTNAME}" \
        --mount "${COMMON_MOUNT_OPT},dst=/var/keys,volume-opt=device=${KEYS_DIR}" \
        --mount "${COMMON_MOUNT_OPT},dst=/var/lib/mysql,volume-opt=device=${MYSQL_DATA_DIR}" \
        --mount "${COMMON_MOUNT_OPT},dst=/var/vmail,volume-opt=device=${VMAIL_DIR}" \
        --mount "${COMMON_MOUNT_OPT},dst=/root/extra,volume-opt=device=${EXTRA_DIR}" \
        --mount "${COMMON_MOUNT_OPT},dst=/var/www,volume-opt=device=${WWW_DIR}" \
        --mount "${COMMON_MOUNT_OPT},dst=/etc/nginx,volume-opt=device=${NGINX_DIR}" \
        --tty \
        --interactive \
        --detach \
        server-a001:latest;

    exit 0;
fi;

echo "Unknown command ${CMD}!";
exit 1;
