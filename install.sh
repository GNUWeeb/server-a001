#!/bin/bash

set -e;
DOCKER_BUILDKIT=1 docker build --secret id=config -t server-a001 .;
