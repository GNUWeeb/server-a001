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
RUN apt-get update && apt-get -y --no-install-recommends install ca-certificates gnupg htop ncurses-term vim software-properties-common sudo wget

# Change root password, and create main user
RUN echo "root:${rootPassword}" | chpasswd \
    && useradd -m ${mainUser} -s /bin/bash \
    && echo "${mainUser}:${mainUserPassword}" | chpasswd \
    && usermod -aG sudo ${mainUser} \
    && sed -i /etc/sudoers -re '/%sudo ALL=(ALL:ALL) ALL/s/^#//g'

# Copy additional apt sources
COPY apt-sources/* /etc/apt/sources.list.d

# Install server components
RUN wget -qO - https://nginx.org/keys/nginx_signing.key | sudo apt-key add - \
    && apt-get update \
    && apt-get -y --no-install-recommends install openssh-server nginx

# Mark port 22/tcp is to be exposed
EXPOSE 22/tcp

COPY docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "tail", "-f", "/dev/null" ]