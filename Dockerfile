# STAGE 1 - Build
FROM debian:13-slim AS builder

ARG NGINX_VERSION=1.28.0
ARG MODSEC_VERSION=v3/master

RUN apt-get update && apt-get install -y \
    gcc make build-essential autoconf automake libtool \
    libcurl4-openssl-dev liblua5.3-dev libfuzzy-dev ssdeep \
    gettext pkg-config libgeoip-dev libyajl-dev doxygen \
    libpcre2-dev zlib1g-dev libssl-dev \
    libmaxminddb-dev git wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/build

RUN git clone --depth 1 -b ${MODSEC_VERSION} \
    https://github.com/owasp-modsecurity/ModSecurity.git \
    /opt/build/ModSecurity

WORKDIR /opt/build/ModSecurity

RUN git submodule init && \
    git submodule update && \
    ./build.sh && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    strip /usr/local/modsecurity/lib/*.so*

RUN git clone --depth 1 \
    https://github.com/owasp-modsecurity/ModSecurity-nginx.git \
    /opt/build/ModSecurity-nginx

RUN git clone --depth 1 \
    https://github.com/leev/ngx_http_geoip2_module.git \
    /opt/build/ngx_http_geoip2_module

WORKDIR /opt/build

RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xzf nginx-${NGINX_VERSION}.tar.gz && \
    rm nginx-${NGINX_VERSION}.tar.gz

WORKDIR /opt/build/nginx-${NGINX_VERSION}

RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --with-compat \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --add-dynamic-module=/opt/build/ModSecurity-nginx \
    --add-dynamic-module=/opt/build/ngx_http_geoip2_module && \
    make -j$(nproc) && \
    make install && \
    make modules && \
    strip /usr/sbin/nginx && \
    strip /opt/build/nginx-${NGINX_VERSION}/objs/*.so

RUN git clone --depth 1 \
    https://github.com/coreruleset/coreruleset.git \
    /opt/build/owasp-crs && \
    cd /opt/build/owasp-crs && \
    rm -rf .git .github tests util

RUN mkdir -p /opt/modsec-artifacts && \
    cp /opt/build/ModSecurity/unicode.mapping /opt/modsec-artifacts/ && \
    cp /opt/build/ModSecurity/modsecurity.conf-recommended \
       /opt/modsec-artifacts/modsecurity.conf

# STAGE 2 - Runtime
FROM debian:13-slim

LABEL maintainer="Xor"
LABEL description="BlackBox WAF"

ARG NGINX_VERSION=1.28.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4 \
    liblua5.3-0 \
    libfuzzy2 \
    libyajl2 \
    libpcre2-8-0 \
    zlib1g \
    libmaxminddb0 \
    libssl3 \
    ca-certificates \
    wget \
    libgeoip1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN mkdir -p /usr/local/modsecurity/lib

COPY --from=builder /usr/local/modsecurity/lib/*.so* \
    /usr/local/modsecurity/lib/

RUN echo "/usr/local/modsecurity/lib" > \
    /etc/ld.so.conf.d/modsecurity.conf && ldconfig

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx

RUN cp /etc/nginx/nginx.conf.default /etc/nginx/nginx.conf

COPY --from=builder /opt/build/nginx-${NGINX_VERSION}/objs/*.so \
    /etc/nginx/modules/

RUN mkdir -p /etc/nginx/modsec

COPY --from=builder /opt/modsec-artifacts/* /etc/nginx/modsec/
COPY --from=builder /opt/build/owasp-crs /opt/owasp-crs-original

RUN cp /opt/owasp-crs-original/crs-setup.conf.example \
    /opt/owasp-crs-original/crs-setup.conf

RUN mkdir -p /opt/modsec-backup && \
    cp /etc/nginx/modsec/modsecurity.conf /opt/modsec-backup/

RUN mkdir -p /etc/nginx/geoip && cd /etc/nginx/geoip && \
    wget -q https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb && \
    wget -q https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb && \
    wget -q https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb

RUN mkdir -p /var/log/nginx /var/cache/nginx /var/run \
    /etc/nginx/conf.d /etc/nginx/owasp-crs

RUN groupadd -r nginx && useradd -r -g nginx -s /sbin/nologin nginx

EXPOSE 80

STOPSIGNAL SIGQUIT

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]