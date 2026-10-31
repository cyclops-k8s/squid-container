FROM ubuntu:26.04 AS builder
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get dist-upgrade --auto-remove --purge --yes \
    && apt-get install --no-install-recommends --yes \
            autoconf-archive \
            automake \
            build-essential \
            ca-certificates \
            cmake \
            ed \
            git \
            gnutls-bin \
            libltdl-dev \
            libssl-dev \
            libtool-bin
WORKDIR /app
RUN git clone --depth 1 --branch v7 https://github.com/squid-cache/squid.git
WORKDIR /app/squid
RUN ./bootstrap.sh
RUN ./configure \
        --build=x86_64-linux-gnu \
        --prefix=/usr \
        --datadir=/usr/share/squid \
        --includedir=/usr/include \
        --infodir=/usr/share/info \
        --libdir=/usr/lib/x86_64-linux-gnu \
        --libexecdir=/usr/lib/squid \
        --localstatedir=/var \
        --mandir=/usr/share/man \
        --runstatedir=/run \
        --sysconfdir=/etc/squid \
        --disable-arch-native \
        --disable-dependency-tracking \
        --disable-maintainer-mode \
        --disable-option-checking \
        --disable-silent-rules \
        --disable-translation \
        --enable-async-io=8 \
        --enable-auth-digest=file \
        --enable-build-info="Ubuntu linux" \
        --enable-cache-digests \
        --enable-delay-pools \
        --enable-esi \
        --enable-eui \
        --enable-follow-x-forwarded-for \
        --enable-icap-client \
        --enable-inline \
        --enable-linux-netfilter \
        --enable-removal-policies=lru,heap \
        --enable-security-cert-validators=fake \
        --enable-ssl-crtd \
        --enable-storeid-rewrite-helpers=file \
        --enable-storeio=ufs,aufs,diskd,rock \
        --enable-url-rewrite-helpers=fake \
        --enable-zph-qos \
        --with-build-environment=default \
        --with-default-user=proxy \
        --with-filedescriptors=65536 \
        --with-large-files \
        --with-logdir=/var/log/squid \
        --with-openssl \
        --with-pidfile=/run/squid.pid \
        --with-swapdir=/var/spool/squid \
        build_alias=x86_64-linux-gnu \
        BUILDCXX=g++ \
        BUILDCXXFLAGS='-g -O2 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -ffile-prefix-map=/build/squid-z38kMa/squid-6.13=. -flto=auto -ffat-lto-objects -fstack-protector-strong -fstack-clash-protection -Wformat -Werror=format-security -fcf-protection -fdebug-prefix-map=/build/squid-z38kMa/squid-6.13=/usr/src/squid-6.13-0ubuntu0.24.04.3 -Wno-error=deprecated-declarations -Wdate-time -D_FORTIFY_SOURCE=3 -Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects -Wl,-z,relro -Wl,-z,now ' \
        CFLAGS='-g -O2 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -ffile-prefix-map=/build/squid-z38kMa/squid-6.13=. -flto=auto -ffat-lto-objects -fstack-protector-strong -fstack-clash-protection -Wformat -Werror=format-security -fcf-protection -fdebug-prefix-map=/build/squid-z38kMa/squid-6.13=/usr/src/squid-6.13-0ubuntu0.24.04.3 -Wno-error=deprecated-declarations' \
        CPPFLAGS='-Wdate-time -D_FORTIFY_SOURCE=3' \
        CXXFLAGS='-g -O2 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -ffile-prefix-map=/build/squid-z38kMa/squid-6.13=. -flto=auto -ffat-lto-objects -fstack-protector-strong -fstack-clash-protection -Wformat -Werror=format-security -fcf-protection -fdebug-prefix-map=/build/squid-z38kMa/squid-6.13=/usr/src/squid-6.13-0ubuntu0.24.04.3 -Wno-error=deprecated-declarations' \
        LDFLAGS='-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects -Wl,-z,relro -Wl,-z,now '
RUN make -j$(( $(nproc) + 10 ))
RUN export DESTDIR=/app/out \
    && make install-strip \
    && rm -rf /app/out/var/run

FROM ubuntu:26.04

WORKDIR /

COPY --from=builder /app/out/etc /etc/
COPY --from=builder /app/out/usr /usr/
COPY --from=builder /app/out/var /var/
COPY entrypoint.sh /entrypoint.sh

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get dist-upgrade --auto-remove --purge --yes \
    && apt-get install --no-install-recommends --yes \
            ca-certificates \
            curl \
            libltdl7 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /squid-state \
    && chown proxy:proxy /run /squid-state \
    && chown -R proxy:proxy /var/spool/squid /var/log/squid /squid-state

USER proxy

HEALTHCHECK --interval=10s --timeout=1s --start-period=5s --retries=3 \
  CMD if [ "$(ps -o pid= -p 1)" ]; then exit 0; else exit 1; fi

ENTRYPOINT ["/entrypoint.sh"]
