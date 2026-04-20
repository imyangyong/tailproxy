#!/bin/sh
# Wait for Tailscale to be ready
while ! tailscale ip -4 >/dev/null 2>&1; do
  sleep 1
done

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Resolve the actual host IP (macOS Docker uses host.docker.internal)
HOST_IP=$(getent hosts host.docker.internal | awk '{print $1}')
if [ -z "${HOST_IP}" ]; then
  # Fallback to default gateway
  HOST_IP=$(ip route | awk '/default/{print $3}')
fi

TS_IP=$(tailscale ip -4)

# 1. For remote Tailscale nodes accessing this machine (e.g., mac-mini -> host:3333)
iptables -t nat -A PREROUTING -i tailscale0 -p tcp -j DNAT --to-destination "${HOST_IP}"
iptables -t nat -A POSTROUTING -d "${HOST_IP}" -j MASQUERADE

# 2. For local SOCKS5 proxy accessing own Tailscale IP (e.g., Surge -> socks5 -> 100.x:3333)
#    Exclude SOCKS5_PORT (SOCKS5 server itself) to avoid redirect loop
if [ -n "${SOCKS5_PORT}" ]; then
  iptables -t nat -A OUTPUT -d "${TS_IP}" -p tcp ! --dport "${SOCKS5_PORT}" -j DNAT --to-destination "${HOST_IP}"
else
  iptables -t nat -A OUTPUT -d "${TS_IP}" -p tcp -j DNAT --to-destination "${HOST_IP}"
fi

echo "Port forwarding enabled: ${TS_IP} -> ${HOST_IP}${SOCKS5_PORT:+ (except port ${SOCKS5_PORT})}"

# Keep running
sleep infinity
