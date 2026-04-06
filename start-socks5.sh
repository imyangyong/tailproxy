#!/bin/sh
while ! tailscale ip -4 >/dev/null 2>&1; do
  sleep 1
done
exec hev-socks5-server /tmp/socks5.yml
