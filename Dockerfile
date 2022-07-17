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
RUN apt-get update && apt-get -y --no-install-recommends install ca-certificates gnupg htop ncurses-term vim software-properties-common sudo wget net-tools rsyslog

# Change root password, and create main user
RUN echo "root:${rootPassword}" | chpasswd \
    && useradd -m ${mainUser} -s /bin/bash \
    && echo "${mainUser}:${mainUserPassword}" | chpasswd \
    && usermod -aG sudo ${mainUser} \
    && sed -i /etc/sudoers -re '/%sudo ALL=(ALL:ALL) ALL/s/^#//g'

# Copy additional apt sources
COPY apt-sources/* /etc/apt/sources.list.d

# Install server components
RUN apt-key adv --fetch-keys https://nginx.org/keys/nginx_signing.key \
    && apt-get update \
    && apt-get -y --no-install-recommends install openssh-server nginx mysql-server

# Mark port 48589/tcp is to be exposed
EXPOSE 48589/tcp 25/tcp 25/tcp 465/tcp 587/tcp 143/tcp 993/tcp

# Apply SSH config and add public keys
COPY etc/ssh/sshd_config /etc/ssh/sshd_config
RUN rm -rf /root/.ssh /home/${mainUser}/.ssh
COPY ssh_keys /root/.ssh
COPY ssh_keys /home/${mainUser}/.ssh
RUN chown -R root:root /root/.ssh \
    && chmod -R 600 /root/.ssh \
    && chown -R ${mainUser}:${mainUser} /home/${mainUser}/.ssh \
    && chmod -R 600 /home/${mainUser}/.ssh


# Mailserver
RUN apt update \
    && apt -y --no-install-recommends install postfix postfix-mysql postfix-policyd-spf-python dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql opendkim opendmarc

COPY mailserver /root/mailserver
RUN --mount=type=secret,required=true,id=config /root/mailserver/setup.sh


COPY docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "tail", "-f", "/dev/null" ]
