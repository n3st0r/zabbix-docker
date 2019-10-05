FROM alpine:3.10
LABEL maintainer="Piotr Dobrysiak"

ARG APK_FLAGS_DEV="--no-cache"

RUN set -eux && \
    addgroup zabbix && \
    adduser \
        --group zabbix \
        --home /var/lib/zabbix/ \
        --system \
        zabbix && \
    mkdir /etc/zabbix && \
    mkdir /var/lib/zabbix && \
    chown -R zabbix:root /var/lib/zabbix && \
    chown -R zabbix:root /etc/zabbix && \
    apk update && \
    apk add \
        bash \
        fping \
        iputils \
        libcurl \
        libevent \
        libldap \
        libssh2 \
        libxml2 \
        net-snmp-agent-libs \
        openipmi-libs \
        pcre \
        postgresql-client \
        postgresql-libs \
        unixodbc && \
    rm -rf /var/cache/apk/*

ARG MAJOR_VERSION=4.2
ARG ZBX_VERSION=${MAJOR_VERSION}.7
ARG ZBX_SOURCES=https://git.zabbix.com/scm/zbx/zabbix.git
ENV ZBX_VERSION=${ZBX_VERSION} ZBX_SOURCES=${ZBX_SOURCES}

RUN set -eux && \
    apk add ${APK_FLAGS_DEV} --virtual build-dependencies \
            alpine-sdk \
            autoconf \
            automake \
            coreutils \
            curl-dev \
            libevent-dev \
            libssh2-dev \
            libxml2-dev \
            net-snmp-dev \
            openipmi-dev \
            openldap-dev \
            pcre-dev \
            postgresql-dev \
            git \
            unixodbc-dev && \

cd /tmp/ && \
    git clone ${ZBX_SOURCES} --branch ${ZBX_VERSION} --depth 1 --single-branch zabbix-${ZBX_VERSION} && \
