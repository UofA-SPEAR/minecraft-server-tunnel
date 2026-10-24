#!/bin/bash
# Runs inside the home container at startup. Builds wg0.conf from home.env.
set -eu

: "${ORACLE_PUBLIC_IP:?ORACLE_PUBLIC_IP missing. Run scripts/gen-keys.sh and put home.env next to compose.yml}"
: "${PEER_PRIVATE_KEY:?PEER_PRIVATE_KEY missing in home.env}"
: "${SERVER_PUBLIC_KEY:?SERVER_PUBLIC_KEY missing in home.env}"
: "${PRESHARED_KEY:?PRESHARED_KEY missing in home.env}"

CONF=/config/wg_confs/wg0.conf

mkdir -p /config/wg_confs
umask 077

cat > "${CONF}" <<EOF
[Interface]
Address = 10.13.13.2/32
PrivateKey = ${PEER_PRIVATE_KEY}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
PresharedKey = ${PRESHARED_KEY}
Endpoint = ${ORACLE_PUBLIC_IP}:51820
AllowedIPs = 10.13.13.0/24
PersistentKeepalive = 25
EOF

chmod 600 "${CONF}"
echo "[spearmc-tunnel] wrote ${CONF} (endpoint ${ORACLE_PUBLIC_IP}:51820)"
