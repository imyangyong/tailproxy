FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx
FROM --platform=$BUILDPLATFORM bitnami/minideb:bookworm AS build

ARG SNELL_VERSION=5.0.1
ARG SOCKS5_VERSION=2.11.2
ARG TARGETPLATFORM

COPY --from=xx / /
COPY get-snell-url.sh /get-snell-url.sh
COPY get-socks5-url.sh /get-socks5-url.sh

RUN xx-info env \
  && install_packages wget unzip ca-certificates \
  # Download snell-server
  && wget -O snell-server.zip $(/get-snell-url.sh ${SNELL_VERSION} $(xx-info arch)) \
  && unzip snell-server.zip \
  && rm snell-server.zip \
  && chmod +x /snell-server \
  && xx-verify /snell-server \
  # Download hev-socks5-server
  && wget -O /hev-socks5-server $(/get-socks5-url.sh ${SOCKS5_VERSION} $(xx-info arch)) \
  && chmod +x /hev-socks5-server \
  && xx-verify /hev-socks5-server

FROM debian:bookworm-slim

LABEL maintainer="SukkaW <https://skk.moe>"

ENV SOCKS5_PORT=
ENV SOCKS5_USER=
ENV SOCKS5_PASSWORD=

ENV SNELL_PORT=
ENV SNELL_PSK=
ENV SNELL_OBFS=

ENV TS_STATE_DIR=/var/lib/tailscale
VOLUME /var/lib/tailscale

RUN apt-get update \
  && apt-get install --no-install-recommends -y ca-certificates iptables iproute2 \
  && rm -rf /var/lib/apt/lists/*

COPY --from=tailscale/tailscale:stable /usr/local/bin/containerboot /usr/local/bin/containerboot
COPY --from=tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/local/bin/tailscaled
COPY --from=tailscale/tailscale:stable /usr/local/bin/tailscale /usr/local/bin/tailscale
COPY --from=build /snell-server /usr/local/bin/snell-server
COPY --from=build /hev-socks5-server /usr/local/bin/hev-socks5-server
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
