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
RUN apt-get update && apt-get -y --no-install-recommends install \
    ca-certificates gnupg htop ncurses-term vim \
    software-properties-common sudo wget net-tools rsyslog \
    openssh-server nginx mysql-server

# Change root password, and create main user
RUN echo "root:${rootPassword}" | chpasswd \
    && useradd -m ${mainUser} -s /bin/bash \
    && echo "${mainUser}:${mainUserPassword}" | chpasswd \
    && usermod -aG sudo ${mainUser} \
    && sed -i /etc/sudoers -re '/%sudo ALL=(ALL:ALL) ALL/s/^#//g'

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
    && apt -y --no-install-recommends install postfix postfix-mysql \
       postfix-policyd-spf-python dovecot-core dovecot-imapd \
       dovecot-lmtpd dovecot-mysql opendkim opendmarc

COPY mailserver /root/mailserver
RUN --mount=type=secret,required=true,id=config /root/mailserver/setup.sh


COPY docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "tail", "-f", "/dev/null" ]
