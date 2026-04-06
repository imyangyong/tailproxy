FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx
FROM --platform=$BUILDPLATFORM bitnami/minideb:bookworm AS build

ARG SNELL_VERSION=5.0.1
ARG SOCKS5_VERSION=2.11.2
ARG TARGETPLATFORM

COPY --from=xx / /
COPY build-get-snell-url.sh /build-get-snell-url.sh
COPY build-get-socks5-url.sh /build-get-socks5-url.sh

RUN xx-info env \
  && install_packages wget unzip ca-certificates \
  # Download snell-server
  && wget -O snell-server.zip $(/build-get-snell-url.sh ${SNELL_VERSION} $(xx-info arch)) \
  && unzip snell-server.zip \
  && rm snell-server.zip \
  && chmod +x /snell-server \
  && xx-verify /snell-server \
  # Download hev-socks5-server
  && wget -O /hev-socks5-server $(/build-get-socks5-url.sh ${SOCKS5_VERSION} $(xx-info arch)) \
  && chmod +x /hev-socks5-server \
  && xx-verify /hev-socks5-server

# Collect glibc runtime libs for snell from target-arch debian
FROM debian:bookworm-slim AS snell-libs

RUN set -eux; \
  mkdir -p /runtime/lib; \
  cp -v /lib/*/ld-linux-*.so.* /runtime/lib/; \
  cp -v /lib/*/libdl.so.* /runtime/lib/; \
  cp -v /lib/*/libm.so.* /runtime/lib/; \
  cp -v /lib/*/libpthread.so.* /runtime/lib/; \
  cp -v /lib/*/libc.so.* /runtime/lib/; \
  cp -v /lib/*/libgcc_s.so.* /runtime/lib/; \
  cp -v /usr/lib/*/libstdc++.so.6* /runtime/lib/

FROM alpine:3.21

LABEL maintainer="SukkaW <https://skk.moe>"

ENV SOCKS5_PORT=
ENV SOCKS5_USER=
ENV SOCKS5_PASSWORD=

ENV SNELL_PORT=
ENV SNELL_PSK=
ENV SNELL_OBFS=

ENV TS_STATE_DIR=/var/lib/tailscale
VOLUME /var/lib/tailscale

RUN apk add --update --no-cache ca-certificates iptables iproute2 multirun

# glibc runtime libs for snell
COPY --from=snell-libs /runtime/lib /lib

COPY --from=tailscale/tailscale:stable /usr/local/bin/containerboot /usr/local/bin/containerboot
COPY --from=tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/local/bin/tailscaled
COPY --from=tailscale/tailscale:stable /usr/local/bin/tailscale /usr/local/bin/tailscale
COPY --from=build /snell-server /usr/local/bin/snell-server
COPY --from=build /hev-socks5-server /usr/local/bin/hev-socks5-server
COPY entrypoint.sh /entrypoint.sh
COPY start-socks5.sh /start-socks5.sh
COPY start-snell.sh /start-snell.sh

ENTRYPOINT ["/entrypoint.sh"]
