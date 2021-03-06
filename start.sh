#!/bin/bash
set -e;

HOSTNAME="gnuweeb.org";
CONTAINER_NAME="server-a001-ct";
MYSQL_DATA_DIR="./storage/mysql_data";
KEYS_DIR="./storage/keys";

SSL_KEYS_DIR="./storage/ssl";
DKIM_KEYS_DIR="./storage/dkim";

mkdir -pv "$MYSQL_DATA_DIR";
mkdir -pv "${KEYS_DIR}/ssl";
mkdir -pv "${KEYS_DIR}/dkim";

MYSQL_DATA_DIR="$(readlink -e "${MYSQL_DATA_DIR}")";
KEYS_DIR="$(readlink -e "${KEYS_DIR}")";

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
        --mount "type=volume,dst=/var/keys,volume-driver=local,volume-opt=type=none,volume-opt=o=bind,volume-opt=device=${KEYS_DIR}" \
        --mount "type=volume,dst=/var/lib/mysql,volume-driver=local,volume-opt=type=none,volume-opt=o=bind,volume-opt=device=${MYSQL_DATA_DIR}" \
        --tty \
        --interactive \
        --detach \
        server-a001:latest;

    exit 0;
fi;

echo "Unknown command ${CMD}!";
exit 1;
