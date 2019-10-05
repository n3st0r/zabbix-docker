FROM alpine:3.10
LABEL maintainer="Piotr Dobrysiak"

ARG APK_FLAGS_DEV="--no-cache"

ENV TERM=xterm MIBDIRS=/usr/share/snmp/mibs:/var/lib/zabbix/mibs \
    MIBS=+ALL \
    ZBX_TYPE=server \
    ZBX_DB_TYPE=postgresql \
    ZBX_OPT_TYPE=none

RUN set -eux && \
    addgroup zabbix && \
    adduser \
        -h /var/lib/zabbix/ \
        -G zabbix \
        -S \
        -D \
        zabbix && \
    mkdir /etc/zabbix && \
    mkdir -p /var/lib/zabbix && \
    chown -R zabbix:root /var/lib/zabbix && \
    chown -R zabbix:root /etc/zabbix && \
    mkdir -p /usr/share/doc/zabbix-${ZBX_TYPE}-${ZBX_DB_TYPE} && \
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
    cd /tmp/zabbix-${ZBX_VERSION} && \
    zabbix_revision=`git rev-parse --short HEAD` && \
    sed -i "s/{ZABBIX_REVISION}/$zabbix_revision/g" include/version.h && \
    ./bootstrap.sh && \
    export CFLAGS="-fPIC -pie -Wl,-z,relro -Wl,-z,now" && \
    ./configure \
            --datadir=/usr/lib \
            --libdir=/usr/lib/zabbix \
            --prefix=/usr \
            --sysconfdir=/etc/zabbix \
            --enable-agent \
            --enable-${ZBX_TYPE} \
            --with-${ZBX_DB_TYPE} \
            --with-ldap \
            --with-libcurl \
            --with-libxml2 \
            --with-net-snmp \
            --with-openipmi \
            --with-openssl \
            --with-ssh2 \
            --with-unixodbc \
            --disable-ipv6 \
            --silent && \
    make -j"$(nproc)" -s dbschema && \
    make -j"$(nproc)" -s && \

    cp src/zabbix_${ZBX_TYPE}/zabbix_${ZBX_TYPE} /usr/sbin/zabbix_${ZBX_TYPE} && \
    cp src/zabbix_get/zabbix_get /usr/bin/zabbix_get && \
    cp src/zabbix_sender/zabbix_sender /usr/bin/zabbix_sender && \
    cp conf/zabbix_${ZBX_TYPE}.conf /etc/zabbix/zabbix_${ZBX_TYPE}.conf && \
    chown --quiet -R zabbix:root /etc/zabbix && \
    cat database/${ZBX_DB_TYPE}/schema.sql > database/${ZBX_DB_TYPE}/create.sql && \
    cat database/${ZBX_DB_TYPE}/images.sql >> database/${ZBX_DB_TYPE}/create.sql && \
    cat database/${ZBX_DB_TYPE}/data.sql >> database/${ZBX_DB_TYPE}/create.sql && \
    gzip database/${ZBX_DB_TYPE}/create.sql && \
    cp database/${ZBX_DB_TYPE}/create.sql.gz /usr/share/doc/zabbix-${ZBX_TYPE}-${ZBX_DB_TYPE}/ && \
    cp database/${ZBX_DB_TYPE}/timescaledb.sql /usr/share/doc/zabbix-${ZBX_TYPE}-${ZBX_DB_TYPE}/ && \
    cd /tmp/ && \
    rm -rf /tmp/zabbix-${ZBX_VERSION}/ && \
    apk del ${APK_FLAGS_COMMON} --purge --no-network \
            build-dependencies && \
    rm -rf /var/cache/apk/*
