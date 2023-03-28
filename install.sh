#!/bin/bash

set -e;
gcc -Wall -Wextra -Os init.c -o init;
DOCKER_BUILDKIT=1 docker build --secret id=config -t server-a001 .;
