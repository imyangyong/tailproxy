#!/bin/sh
while ! tailscale ip -4 >/dev/null 2>&1; do
  sleep 1
done
exec snell-server -c /tmp/snell.conf
