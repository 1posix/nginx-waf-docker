# syntax=docker/dockerfile:1.7

FROM debian:13-slim AS builder

ARG NGINX_VERSION=1.30.4
ARG NGINX_COMMIT=017cf98dcce217946572a896f0992370475e189f
ARG MODSECURITY_COMMIT=7ea9fefbe0ba409d8733b4d682c8c4c059cd028d
ARG MODSECURITY_NGINX_COMMIT=3f4b57df10ce43b1f1c722141f7621dc64838be8
ARG CRS_COMMIT=3b89d5a05322f448b4b74b9cadc5fb05ac6915ad
ARG GEOIP2_COMMIT=cbaa35461c62a99d2577e6bae3273492502d8769

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       autoconf \
       automake \
       bison \
       build-essential \
       ca-certificates \
       curl \
       flex \
       git \
       libcurl4-openssl-dev \
       liblmdb-dev \
       libmaxminddb-dev \
       libpcre2-dev \
       libssl-dev \
       libtool \
       libxml2-dev \
       libyajl-dev \
       pkgconf \
       zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Fetch an exact commit rather than a moving branch/tag.
RUN git init ModSecurity \
    && cd ModSecurity \
    && git remote add origin https://github.com/owasp-modsecurity/ModSecurity.git \
    && git fetch --depth 1 origin "${MODSECURITY_COMMIT}" \
    && git checkout --detach FETCH_HEAD \
    && git submodule update --init --recursive --depth 1

WORKDIR /src/ModSecurity
RUN ./build.sh \
    && ./configure --prefix=/usr/local/modsecurity \
    && make -j"$(nproc)" \
    && make install

WORKDIR /src
RUN git init ModSecurity-nginx \
    && cd ModSecurity-nginx \
    && git remote add origin https://github.com/owasp-modsecurity/ModSecurity-nginx.git \
    && git fetch --depth 1 origin "${MODSECURITY_NGINX_COMMIT}" \
    && git checkout --detach FETCH_HEAD

RUN git init ngx_http_geoip2_module \
    && cd ngx_http_geoip2_module \
    && git remote add origin https://github.com/leev/ngx_http_geoip2_module.git \
    && git fetch --depth 1 origin "${GEOIP2_COMMIT}" \
    && git checkout --detach FETCH_HEAD

RUN git init coreruleset \
    && cd coreruleset \
    && git remote add origin https://github.com/coreruleset/coreruleset.git \
    && git fetch --depth 1 origin "${CRS_COMMIT}" \
    && git checkout --detach FETCH_HEAD \
    && rm -rf .git .github tests util

WORKDIR /src
RUN git init nginx \
    && cd nginx \
    && git remote add origin https://github.com/nginx/nginx.git \
    && git fetch --depth 1 origin "${NGINX_COMMIT}" \
    && git checkout --detach FETCH_HEAD

WORKDIR /src/nginx
RUN ./auto/configure \
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --modules-path=/usr/lib/nginx/modules \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/dev/stderr \
      --http-log-path=/dev/stdout \
      --pid-path=/tmp/nginx.pid \
      --lock-path=/tmp/nginx.lock \
      --with-compat \
      --with-file-aio \
      --with-threads \
      --with-http_ssl_module \
      --with-http_v2_module \
      --with-http_realip_module \
      --with-http_stub_status_module \
      --with-http_gzip_static_module \
      --with-http_auth_request_module \
      --add-dynamic-module=/src/ModSecurity-nginx \
      --add-dynamic-module=/src/ngx_http_geoip2_module \
    && make -j"$(nproc)" \
    && make modules -j"$(nproc)" \
    && make install \
    && mkdir -p /usr/lib/nginx/modules \
    && cp objs/*.so /usr/lib/nginx/modules/ \
    && strip /usr/sbin/nginx \
    && strip /usr/lib/nginx/modules/*.so

RUN mkdir -p /image/opt/modsecurity /image/opt/owasp-crs \
    && cp /src/ModSecurity/modsecurity.conf-recommended /image/opt/modsecurity/modsecurity.conf \
    && cp /src/ModSecurity/unicode.mapping /image/opt/modsecurity/unicode.mapping \
    && cp -a /src/coreruleset/. /image/opt/owasp-crs/ \
    && sed -i 's#^SecUnicodeMapFile .*#SecUnicodeMapFile /opt/modsecurity/unicode.mapping 20127#' \
       /image/opt/modsecurity/modsecurity.conf


FROM debian:13-slim AS runtime

ARG NGINX_VERSION=1.30.4
ARG NGINX_COMMIT=017cf98dcce217946572a896f0992370475e189f
ARG MODSECURITY_COMMIT
ARG MODSECURITY_NGINX_COMMIT
ARG CRS_COMMIT
ARG GEOIP2_COMMIT
ARG WAF_UID=10001
ARG WAF_GID=10001

LABEL org.opencontainers.image.title="nginx-waf-docker" \
      org.opencontainers.image.version="2.0.3" \
      org.opencontainers.image.description="Nginx + ModSecurity v3 + OWASP CRS LTS reverse-proxy WAF" \
      org.opencontainers.image.source="https://github.com/1posix/nginx-waf-docker"

ENV DEBIAN_FRONTEND=noninteractive \
    LD_LIBRARY_PATH=/usr/local/modsecurity/lib \
    TZ=Europe/Paris

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       libcurl4t64 \
       liblmdb0 \
       libmaxminddb0 \
       libpcre2-8-0 \
       libssl3t64 \
       libstdc++6 \
       libxml2 \
       libyajl2 \
       tzdata \
       zlib1g \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid "${WAF_GID}" waf \
    && useradd --system --uid "${WAF_UID}" --gid waf \
       --home-dir /nonexistent --shell /usr/sbin/nologin waf

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /usr/lib/nginx/modules /usr/lib/nginx/modules
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/local/modsecurity /usr/local/modsecurity
COPY --from=builder /image/opt/modsecurity /opt/modsecurity
COPY --from=builder /image/opt/owasp-crs /opt/owasp-crs

RUN printf '%s\n' '/usr/local/modsecurity/lib' > /etc/ld.so.conf.d/modsecurity.conf \
    && ldconfig \
    && mkdir -p \
       /etc/nginx/conf.d \
       /etc/nginx/snippets \
       /etc/nginx/sites-enabled \
       /etc/modsecurity/custom \
       /var/lib/geoip \
       /var/log/modsecurity \
       /usr/share/nginx/html/custom \
    && chown -R "${WAF_UID}:${WAF_GID}" /var/log/modsecurity /var/lib/geoip

COPY docker/entrypoint.sh /usr/local/bin/waf-entrypoint
RUN chmod 0755 /usr/local/bin/waf-entrypoint

USER ${WAF_UID}:${WAF_GID}

EXPOSE 8080 8443
STOPSIGNAL SIGQUIT

ENTRYPOINT ["/usr/local/bin/waf-entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
