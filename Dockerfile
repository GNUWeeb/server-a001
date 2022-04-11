FROM ubuntu:focal as base

# Build args
ARG rootPassword=somerootpassword
ARG mainUser=user
ARG mainUserPassword=someuserpassword

# Tell apt that DEBIAN_FRONTEND is noninteractive
ARG DEBIAN_FRONTEND=noninteractive

# Unminimize the Ubuntu image first
RUN yes | unminimize

# Install base packages
RUN apt-get update && apt-get -y --no-install-recommends install ca-certificates gnupg htop ncurses-term vim software-properties-common sudo

# Change root password, and create main user
RUN echo "root:${rootPassword}" | chpasswd \
    && useradd -m ${mainUser} -s /bin/bash \
    && echo "${mainUser}:${mainUserPassword}" | chpasswd \
    && usermod -aG sudo ${mainUser} \
    && sed -i /etc/sudoers -re '/%sudo ALL=(ALL:ALL) ALL/s/^#//g'

# Install server components
RUN apt-get update && apt-get -y --no-install-recommends install openssh-server

# Mark port 22/tcp is to be exposed
EXPOSE 22/tcp

COPY docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "tail", "-f", "/dev/null" ]