# TailProxy

Access your Tailscale Network or route your traffic through Tailscale exit nodes via a SOCKS5 proxy or Snell proxy, without interfering with your system-wide network configuration.

## What is TailProxy?

TailProxy is a Docker image that runs Tailscale (with Tailscale's internal `containerboot`), and exposes a SOCKS5/Surge Snell proxy. This gives you the flexibility to:

- Avoid installing Tailscale GUI client on your host machine, which may interfere with your existing network configuration or cause other issues, most notably if you are already using another VPN client.
- Bypass VPN limitations in applications that don't support traditional VPNs
- Better integrate with your existing applications that support SOCKS5 proxy
- Better integrate with Surge for Mac, allowing you to split-tunnel, routing only specific apps or domains through Tailscale, while keeping the rest of your traffic as is.

## Quick start

```bash
docker run -d \
  --name tailproxy \
  # this is required for setting up Tailscale
  --cap-add NET_ADMIN \
  # expose Docker container's tun device to Tailscale
  --device /dev/net/tun:/dev/net/tun \

  # --- Begin of Tailscale configuration ---
  # You can specify Tailscale environment variables as needed.

  # Tailscale Auth Key: https://login.Tailscale.com/admin/settings/keys
  -e TS_AUTHKEY=tskey-auth-XXXXX \
  # Optional Tailscale magic DNS hostname
  -e TS_HOSTNAME=tailproxy-1 \

  # Optional, Tailscale state directory (defaults to /var/lib/Tailscale)
  # -e TS_STATE_DIR=/var/lib/Tailscale \
  # Optional, persist Tailscale state (including authentication) across container restarts
  # Must be consistent with TS_STATE_DIR if customized
  # -v Tailscale-state:/var/lib/Tailscale \

  # You can specify other Tailscale environment variables as needed, See Tailscale documentation for details. E.g.:
  # -e TS_ACCEPT_DNS=true \

  # --- End of Tailscale configuration ---

  # Optional SOCKS5 port. When not set, the SOCKS5 proxy will be disabled.
  -e SOCKS5_PORT=11188 \
  # Optional Snell port. When not set, the Snell proxy will be disabled.
  # You must enable at least one of SOCKS5_PORT or SNELL_PORT for TailProxy to be useful.
  -e SNELL_PORT=11189 \
  # Snell PSK (pre-shared key) for authentication.
  # If you do not provide a PSK, a random one will be generated and printed in the container logs on startup.
  -e SNELL_PSK=my-secret-psk \
  # Optional Snell obfuscation method. Default is "off".
  -e SNELL_OBFS=off \
  # Optional, expose proxy ports to the host.
  -p 11188:11188 \
  -p 11189:11189 \
  --restart unless-stopped \
  tailproxy:latest
```

> You can also use `docker compose` to manage the TailProxy, and here is the [`docker-compose.example.yml`](docker-compose.example.yml).

After the container is up and running, you can verify the proxy is working:

```bash
# Via SOCKS5
curl -x socks5://127.0.0.1:{socks5 port} http://100.100.100.100
```

## Build image from source

```bash
# Single platform (current arch)
docker build -t tailproxy .

# Multi-arch
docker buildx build --platform linux/amd64,linux/arm64 -t tailproxy .
```

## License

[Apache License 2.0](LICENSE)

----

**TailProxy** © [Sukka](https://github.com/SukkaW), Authored and maintained by Sukka with help from contributors ([list](https://github.com/SukkaW/tailproxy/graphs/contributors)).

> [Personal Website](https://skk.moe) · [Blog](https://blog.skk.moe) · GitHub [@SukkaW](https://github.com/SukkaW) · Telegram Channel [@SukkaChannel](https://t.me/SukkaChannel) · Twitter [@isukkaw](https://twitter.com/isukkaw) · BlueSky [@skk.moe](https://bsky.app/profile/skk.moe) · Mastodon [@sukka@acg.mn](https://acg.mn/@sukka)

<p align="center">
  <a href="https://github.com/sponsors/SukkaW/">
    <img src="https://sponsor.cdn.skk.moe/sponsors.svg"/>
  </a>
</p>
