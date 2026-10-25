#!/bin/bash
# Builds wg0.conf from environment variables and brings the tunnel up with wireguard-go.
set -eu

: "${ORACLE_PUBLIC_IP:?ORACLE_PUBLIC_IP missing. Copy home.env to .env next to compose.yml}"
: "${PEER_PRIVATE_KEY:?PEER_PRIVATE_KEY missing in .env}"
: "${SERVER_PUBLIC_KEY:?SERVER_PUBLIC_KEY missing in .env}"
: "${PRESHARED_KEY:?PRESHARED_KEY missing in .env}"

case "${ORACLE_PUBLIC_IP}" in
  *YOUR_ORACLE*|"") echo "ORACLE_PUBLIC_IP is still the placeholder. Edit .env/home.env" >&2; exit 1;;
esac

CONF=/etc/wireguard/wg0.conf
mkdir -p /etc/wireguard
umask 077
cat > "${CONF}" <<CONF_EOF
[Interface]
Address = 10.13.13.2/32
PrivateKey = ${PEER_PRIVATE_KEY}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
PresharedKey = ${PRESHARED_KEY}
Endpoint = ${ORACLE_PUBLIC_IP}:51820
AllowedIPs = 10.13.13.0/24
PersistentKeepalive = 25
CONF_EOF

export WG_QUICK_USERSPACE_IMPLEMENTATION=wireguard-go
wg-quick up wg0
echo "[spearmc-tunnel] wg0 up via wireguard-go (endpoint ${ORACLE_PUBLIC_IP}:51820)"

down() { wg-quick down wg0 || true; exit 0; }
trap down TERM INT
while true; do sleep 3600 & wait $!; done
