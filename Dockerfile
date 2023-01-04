FROM nginx:1.21.4-alpine AS builder

# nginx:alpine contains NGINX_VERSION environment variable, like so:
# ENV NGINX_VERSION 1.15.0

ENV NGINX_VTS_VERSION 0.1.18

# Download sources
RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz
RUN   wget "https://github.com/vozlt/nginx-module-vts/archive/refs/tags/v${NGINX_VTS_VERSION}.tar.gz" -O vts.tar.gz



# For latest build deps, see https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile
RUN apk add --no-cache --virtual .build-deps \
  gcc \
  libc-dev \
  make \
  openssl-dev \
  pcre-dev \
  zlib-dev \
  linux-headers \
  curl \
  gnupg \
  libxslt-dev \
  gd-dev \
  geoip-dev

# Reuse same cli arguments as the nginx:alpine image used to build
RUN mkdir -p /usr/src
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
	tar -zxC /usr/src -f nginx.tar.gz && \
  tar -xzvf "vts.tar.gz" && \
  NGINX_VTS_DIR="$(pwd)/nginx-module-vts-${NGINX_VTS_VERSION}" && \
  cd /usr/src/nginx-$NGINX_VERSION && \
  ./configure --with-compat $CONFARGS --add-dynamic-module=$NGINX_VTS_DIR && \
  make && make install

FROM nginx:1.21.4-alpine
# Extract the dynamic module NCHAN from the builder image
COPY --from=builder /usr/local/nginx/modules/ngx_http_vhost_traffic_status_module.so /usr/local/nginx/modules/ngx_http_vhost_traffic_status_module.so