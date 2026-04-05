#!/bin/bash
set -e

launch() {
  if [ -z "${SOCKS5_PORT}" ] && [ -z "${SNELL_PORT}" ]; then
    echo "ERROR: At least one of SOCKS5_PORT or SNELL_PORT must be set"
    exit 1
  fi

  # Ensure containerboot uses tun mode
  export TS_USERSPACE="${TS_USERSPACE:-false}"

  # Start containerboot in the background — handles all TS_* env vars
  containerboot &

  # Wait for tailscale to be connected
  echo "Waiting for tailscale to connect..."
  while ! tailscale status --json 2>/dev/null | grep -q '"BackendState": "Running"'; do
    sleep 1
  done

  echo "============================================"
  echo "  tailscale is up ($(tailscale ip -4))"

  # Start hev-socks5-server if SOCKS5_PORT is set
  if [ -n "${SOCKS5_PORT}" ]; then
    cat > /tmp/socks5.yml <<EOF
main:
  workers: 4
  port: ${SOCKS5_PORT}
  listen-address: '::'
  listen-ipv6-only: false
EOF

    if [ -n "${SOCKS5_USER}" ] && [ -n "${SOCKS5_PASSWORD}" ]; then
      cat >> /tmp/socks5.yml <<EOF

auth:
  username: ${SOCKS5_USER}
  password: ${SOCKS5_PASSWORD}
EOF
    fi

    echo "  hev-socks5-server listening on :${SOCKS5_PORT}"
    if [ -n "${SOCKS5_USER}" ] && [ -n "${SOCKS5_PASSWORD}" ]; then
      echo "    socks5 auth: ${SOCKS5_USER}:${SOCKS5_PASSWORD}"
    else
      echo "    socks5 auth: disabled"
    fi

    hev-socks5-server /tmp/socks5.yml &
  fi

  # Start snell-server if SNELL_PORT is set
  if [ -n "${SNELL_PORT}" ]; then
    SNELL_PSK="${SNELL_PSK:-$(head -c 16 /dev/urandom | od -A n -t x1 | tr -d ' \n')}"
    SNELL_OBFS="${SNELL_OBFS:-off}"

    cat > /tmp/snell.conf <<EOF
[snell-server]
listen = 0.0.0.0:${SNELL_PORT}
psk = ${SNELL_PSK}
obfs = ${SNELL_OBFS}
EOF

    echo "  snell-server listening on :${SNELL_PORT}"
    echo "    snell psk: ${SNELL_PSK}"
    echo "    snell obfs: ${SNELL_OBFS}"

    snell-server -c /tmp/snell.conf &
  fi

  echo "============================================"

  # Wait for any process to exit
  wait -n
  exit $?
}

if [ -z "$*" ]; then
  launch
else
  exec "$@"
fi
