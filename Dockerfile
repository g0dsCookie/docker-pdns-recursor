FROM alpine:3.11

RUN set -eu \
 && apk add --no-cache --virtual .pdns-deps \
	openssl boost lua5.1 libsodium \
	net-snmp protobuf \
 && mkdir /var/lib/powerdns

ARG MAJOR
ARG MINOR
ARG PATCH

RUN set -eu \
 # install build deps
 && apk add --no-cache --virtual .pdns-bdeps \
	gcc g++ libc-dev rpcgen make tar bzip2 curl \
	linux-headers openssl-dev boost-dev lua5.1-dev \
	libsodium-dev net-snmp-dev protobuf-dev \
 && BDIR="$(mktemp -d)" && cd "${BDIR}" \
 && PDNS_VERSION="${MAJOR}.${MINOR}.${PATCH}" \
 && MAKEOPTS="-j$(($(nproc)-1))" \
 # download pdns sources
 && curl -sSL -o "pdns-recursor-${PDNS_VERSION}.tar.bz2" "https://downloads.powerdns.com/releases/pdns-recursor-${PDNS_VERSION}.tar.bz2" \
 && tar -xjf "pdns-recursor-${PDNS_VERSION}.tar.bz2" \
 && cd "pdns-recursor-${PDNS_VERSION}" \
 # configure pdns
 && ./configure --prefix=/usr --sysconfdir=/etc/powerdns \
	--with-lua=lua --disable-static --disable-systemd \
	--with-libsodium --with-protobuf --with-net-snmp \
 # compile and install
 && make ${MAKEOPTS} \
 && make install \
 # cleanup
 && cd && rm -r "${BDIR}" \
 && apk del .pdns-bdeps

EXPOSE 53/udp
EXPOSE 53/tcp

VOLUME /etc/powerdns
WORKDIR /var/lib/powerdns

ENTRYPOINT ["/usr/sbin/pdns_recursor", "--config-dir=/etc/powerdns", "--daemon=no"]
