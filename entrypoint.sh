#!/bin/sh
set -e

launch() {
  if [ -z "${SOCKS5_PORT}" ] && [ -z "${SNELL_PORT}" ]; then
    echo "ERROR: At least one of SOCKS5_PORT or SNELL_PORT must be set"
    exit 1
  fi

  # Ensure containerboot uses tun mode by default
  export TS_USERSPACE="${TS_USERSPACE:-false}"

  # Build multirun command list
  MULTIRUN_CMDS="containerboot"

  # Generate hev-socks5-server config
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

    MULTIRUN_CMDS="${MULTIRUN_CMDS} /start-socks5.sh"
  fi

  # Generate snell-server config
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

    MULTIRUN_CMDS="${MULTIRUN_CMDS} /start-snell.sh"
  fi

  echo "============================================"

  # multirun handles PID 1, signal forwarding, zombie reaping,
  # and kills all children when any one exits
  exec multirun ${MULTIRUN_CMDS}
}

if [ -z "$*" ]; then
  launch
else
  exec "$@"
fi
