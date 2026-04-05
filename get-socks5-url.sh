#!/bin/bash

set -e

VERSION=$1
ARCH=$2

if [ "${ARCH}" == "amd64" ]; then
  echo "https://github.com/heiher/hev-socks5-server/releases/download/${VERSION}/hev-socks5-server-linux-x86_64"
elif [ "${ARCH}" == "arm64" ]; then
  echo "https://github.com/heiher/hev-socks5-server/releases/download/${VERSION}/hev-socks5-server-linux-arm64"
elif [ "${ARCH}" == "arm" ]; then
  echo "https://github.com/heiher/hev-socks5-server/releases/download/${VERSION}/hev-socks5-server-linux-arm32v7hf"
else
  echo "Usage: get-socks5-url.sh VERSION ARCH"
  exit 1
fi

exit 0
